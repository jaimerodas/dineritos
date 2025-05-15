require "rails_helper"

RSpec.describe MovementsController, type: :request do
  fixtures :users, :accounts

  let(:user) { users(:test_user) }
  let(:account) { accounts(:savings_account) }

  describe "#index" do
    context "when user is logged in" do
      stub_current_user { user }
      before { travel_to Date.new(2023, 1, 1) }

      after { travel_back }

      it "returns a successful HTML response" do
        get account_movements_path(account)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end

      it "handles month parameter" do
        get account_movements_path(account), params: {month: "2023-02"}
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not logged in" do
      it "redirects to login page" do
        get account_movements_path(account)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
