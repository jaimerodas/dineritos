require "rails_helper"

RSpec.describe LoginsController, type: :controller do
  fixtures :users

  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when not logged in" do
      it "renders the login page" do
        get :show
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end
    end

    context "when logged in" do
      stub_current_user { user }

      it "redirects to the root path" do
        get :show
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #create" do
    context "when not logged in" do
      it "redirects to the email login path with the provided email" do
        post :create, params: {session: {email: user.email}}
        expect(response).to redirect_to(
          email_login_path(session: {email: user.email.downcase})
        )
      end
    end

    context "when logged in" do
      stub_current_user { user }

      it "redirects to the root path" do
        post :create, params: {session: {email: user.email}}
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #email" do
    before { ActionMailer::Base.deliveries.clear }

    context "when not logged in" do
      context "with a valid email" do
        it "creates a session and sends a login email" do
          expect {
            get :email, params: {session: {email: user.email}}
          }.to change { user.sessions.count }.by(1)
            .and change { ActionMailer::Base.deliveries.count }.by(1)
          mail = ActionMailer::Base.deliveries.last
          expect(mail.to).to include(user.email)
        end
      end

      context "with an invalid email" do
        it "does not create a session and renders the email form" do
          expect {
            get :email, params: {session: {email: "unknown@example.com"}}
          }.not_to change { user.sessions.count }
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/html")
        end
      end
    end

    context "when logged in" do
      stub_current_user { user }

      it "redirects to the root path" do
        get :email, params: {session: {email: user.email}}
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET #discovery" do
    let(:fake_options) do
      Struct.new(:challenge) do
        def as_json(_opts = {})
          {"challenge" => challenge}
        end
      end.new("fake_challenge")
    end

    context "when not logged in" do
      before { allow(WebAuthn::Credential).to receive(:options_for_get).and_return(fake_options) }

      it "sets the session challenge and returns JSON options" do
        get :discovery, format: :json
        expect(session[:webauthn_discovery_challenge]).to eq("fake_challenge")
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
        json = JSON.parse(response.body)
        expect(json["callback_url"]).to eq(callback_login_path(format: :json))
        expect(json["get_options"]).to eq("challenge" => "fake_challenge")
      end
    end

    context "when logged in" do
      stub_current_user { user }
      before { allow(WebAuthn::Credential).to receive(:options_for_get).and_return(fake_options) }

      it "redirects to the root path" do
        get :discovery, format: :json
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #callback" do
    let(:raw_id) { "\x01\x02" }
    let(:external_id) { Base64.strict_encode64(raw_id) }
    let(:web_credential) { double("WebAuthnCredential", raw_id: raw_id, public_key: "new_key", sign_count: 5) }

    context "when not logged in" do
      before { session[:webauthn_discovery_challenge] = "fake_challenge" }

      context "with an unknown credential" do
        before do
          allow(WebAuthn::Credential).to receive(:from_get).and_return(web_credential)
        end

        it "returns an unknown credential error" do
          post :callback, params: {}, format: :json
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to match(/Unknown credential/)
        end
      end

      context "with a valid credential" do
        before do
          user.passkeys.create!(external_id: external_id,
            nickname: "key", public_key: "old_key", sign_count: 1)
          allow(WebAuthn::Credential).to receive(:from_get).and_return(web_credential)
          allow(web_credential).to receive(:verify)
        end

        it "verifies, logs in the user, updates sign_count, and returns ok" do
          expect {
            post :callback, params: {}, format: :json
          }.to change { session[:user_id] }.to(user.id)
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json).to include("status" => "ok")
          pk = user.passkeys.find_by(external_id: external_id)
          expect(pk.sign_count).to eq(5)
          expect(session[:webauthn_discovery_challenge]).to be_nil
        end
      end

      context "when verification fails" do
        before do
          user.passkeys.create!(external_id: external_id,
            nickname: "key", public_key: "old_key", sign_count: 1)
          allow(WebAuthn::Credential).to receive(:from_get).and_return(web_credential)
          allow(web_credential).to receive(:verify)
            .and_raise(WebAuthn::Error.new("verification failed"))
        end

        it "returns a verification error" do
          post :callback, params: {}, format: :json
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to match(/Verification failed: verification failed/)
          expect(session[:webauthn_discovery_challenge]).to be_nil
        end
      end
    end

    context "when logged in" do
      stub_current_user { user }

      it "redirects to the root path" do
        post :callback, params: {}, format: :json
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
