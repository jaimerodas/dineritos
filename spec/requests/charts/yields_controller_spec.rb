require "rails_helper"

RSpec.describe Charts::YieldsController, type: :request do
  fixtures :users

  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get chart_data_yields_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }

      it "returns a successful JSON response" do
        get chart_data_yields_path
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end
    end
  end
end
