require "rails_helper"

RSpec.describe InvestmentsController, type: :request do
  fixtures :users
  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get root_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }
      before { get root_path }

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "returns HTML content" do
        expect(response.content_type).to include("text/html")
      end

      it "includes the investments Stimulus controller attribute" do
        expect(response.body).to include('data-controller="investments"')
      end
    end
  end
end
