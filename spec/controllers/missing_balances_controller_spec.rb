require "rails_helper"

RSpec.describe MissingBalancesController, type: :controller do
  fixtures :users

  let(:user) { users(:test_user) }

  describe "GET #index" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }

      it "returns a successful response" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end
    end
  end
end
