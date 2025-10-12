require "rails_helper"

RSpec.describe PasskeysController, type: :controller do
  fixtures :users

  let(:user) { users(:test_user) }

  describe "GET #new" do
    context "when not logged in" do
      it "redirects to login page" do
        get :new
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }

      it "returns a successful response and assigns a new passkey" do
        get :new
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
        passkey = controller.instance_variable_get(:@passkey)
        expect(passkey).to be_a_new(Passkey)
      end
    end
  end

  describe "POST #create" do
    context "when not logged in" do
      it "redirects to login page" do
        post :create, params: {}, format: :json
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }

      let(:fake_options) do
        Struct.new(:challenge) do
          def as_json(_opts = {})
            {"challenge" => challenge}
          end
        end.new("fake_challenge")
      end

      before do
        allow(WebAuthn::Credential).to receive(:options_for_create).and_return(fake_options)
      end

      it "sets the session challenge and returns JSON options" do
        post :create, params: {}, format: :json
        expect(session[:create_challenge]).to eq("fake_challenge")
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
        json = JSON.parse(response.body)
        expect(json).to eq("challenge" => "fake_challenge")
      end
    end
  end

  describe "POST #callback" do
    let(:web_credential) { double("WebAuthnCredential", raw_id: "\x01\x02", public_key: "public_key", sign_count: 42) }

    context "when not logged in" do
      it "redirects to login page" do
        post :callback, params: {nickname: "MyKey"}, format: :json
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }
      before { session[:create_challenge] = "fake_challenge" }

      context "with successful verification" do
        before do
          allow(WebAuthn::Credential).to receive(:from_create).and_return(web_credential)
          allow(web_credential).to receive(:verify).with("fake_challenge")
        end

        it "creates a new passkey and returns status ok" do
          expect {
            post :callback, params: {nickname: "MyKey"}, format: :json
          }.to change(Passkey, :count).by(1)
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json).to include("status" => "ok")
          passkey = Passkey.last
          expect(passkey.user).to eq(user)
          expect(passkey.nickname).to eq("MyKey")
          expect(passkey.external_id).to eq(Base64.strict_encode64(web_credential.raw_id))
          expect(passkey.public_key).to eq(web_credential.public_key)
          expect(passkey.sign_count).to eq(web_credential.sign_count)
          expect(session[:create_challenge]).to be_nil
        end
      end

      context "when verification fails" do
        before do
          allow(WebAuthn::Credential).to receive(:from_create).and_return(web_credential)
          allow(web_credential).to receive(:verify).and_raise(WebAuthn::Error.new("verification error"))
        end

        it "does not create a passkey and returns an error" do
          expect {
            post :callback, params: {nickname: "MyKey"}, format: :json
          }.not_to change(Passkey, :count)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to match(/Verification failed: verification error/)
          expect(session[:create_challenge]).to be_nil
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:passkey) do
      # Create a passkey associated with the user for deletion
      user.passkeys.create!(external_id: "ext_id", nickname: "ToDelete", public_key: "pub", sign_count: 1)
    end

    context "when not logged in" do
      it "redirects to login page" do
        delete :destroy, params: {id: passkey.id}
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }

      it "destroys the passkey and redirects to settings page" do
        expect {
          delete :destroy, params: {id: passkey.id}
        }.to change(Passkey, :count).by(-1)
        expect(response).to redirect_to(settings_path)
        expect(flash[:notice]).to eq("Passkey eliminada")
      end
    end
  end
end
