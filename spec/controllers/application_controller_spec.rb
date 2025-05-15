require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  # Define an anonymous controller to expose current_user
  controller do
    def index
      if current_user
        render plain: "user:#{current_user.id}"
      else
        render plain: "none"
      end
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  fixtures :users
  let(:user) { users(:test_user) }

  describe "#current_user" do
    context "when no session and no cookies" do
      it "returns nil" do
        get :index
        expect(response.body).to eq("none")
        expect(session[:user_id]).to be_nil
      end
    end

    context "when session[:user_id] is set" do
      before { session[:user_id] = user.id }

      it "returns the user" do
        get :index
        expect(response.body).to eq("user:#{user.id}")
      end
    end

    context "when cookies.signed[:session_id] and valid remember_token are present" do
      let!(:session_record) do
        s = user.sessions.create!
        s.remember
        s
      end

      before do
        cookies.signed[:session_id] = session_record.id
        cookies[:remember_token] = session_record.remember_token
      end

      it "authenticates via cookie, logs in, refreshes session, and returns the user" do
        original_expires = session_record.expires_at
        get :index
        expect(response.body).to eq("user:#{user.id}")
        expect(session[:user_id]).to eq(user.id)
        refreshed = Session.find(session_record.id)
        expect(refreshed.expires_at).to be > original_expires
      end
    end

    context "when cookies.signed[:session_id] is present but remember_token is invalid" do
      let!(:session_record) do
        s = user.sessions.create!
        s.remember
        s
      end

      before do
        cookies.signed[:session_id] = session_record.id
        cookies[:remember_token] = "bad_token"
      end

      it "does not authenticate and returns nil" do
        get :index
        expect(response.body).to eq("none")
        expect(session[:user_id]).to be_nil
      end
    end

    context "when cookies.signed[:session_id] is present but session is expired" do
      let!(:session_record) do
        s = user.sessions.create!
        s.remember
        s.update_column(:expires_at, 1.hour.ago)
        s
      end

      before do
        cookies.signed[:session_id] = session_record.id
        cookies[:remember_token] = session_record.remember_token
      end

      it "does not authenticate expired session and returns nil" do
        get :index
        expect(response.body).to eq("none")
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
