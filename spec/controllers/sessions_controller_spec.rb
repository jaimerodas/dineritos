require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  fixtures :users

  let(:user) { users(:test_user) }

  describe "POST #create" do
    context "with valid user and valid token" do
      it "logs in the user, sets cookies, and redirects to root_path" do
        session_record = user.sessions.create!
        post :create, params: {email: user.email, token: session_record.token}

        expect(session[:user_id]).to eq(user.id)
        expect(cookies.signed[:session_id]).to eq(session_record.id)

        remember_token = cookies[:remember_token]
        expect(remember_token).not_to be_nil
        reloaded = Session.find(session_record.id)
        expect(reloaded.authenticated?(remember_token)).to be true

        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid email" do
      it "does not log in and redirects to root_path" do
        post :create, params: {email: "nonexistent@example.com", token: "whatever"}

        expect(session[:user_id]).to be_nil
        expect(cookies.signed[:session_id]).to be_nil
        expect(cookies[:remember_token]).to be_nil

        expect(response).to redirect_to(root_path)
      end
    end

    context "with valid email but invalid token" do
      it "does not log in and redirects to root_path" do
        user.sessions.create!
        post :create, params: {email: user.email, token: "invalidtoken"}

        expect(session[:user_id]).to be_nil
        expect(cookies.signed[:session_id]).to be_nil
        expect(cookies[:remember_token]).to be_nil

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE #destroy" do
    it "logs out the user, deletes session record, clears cookies, and redirects to login_path" do
      session_record = user.sessions.create!
      session[:user_id] = user.id
      cookies.signed[:session_id] = session_record.id
      cookies[:remember_token] = "token_value"

      delete :destroy

      expect(session[:user_id]).to be_nil
      expect(cookies.signed[:session_id]).to be_nil
      expect(cookies[:remember_token]).to be_nil
      expect(Session.find_by(id: session_record.id)).to be_nil

      expect(response).to redirect_to(login_path)
    end
  end
end
