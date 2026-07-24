require "rails_helper"

RSpec.describe Charts::BalancesController, type: :request do
  fixtures :users

  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get chart_data_balances_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }

      it "returns a successful JSON response" do
        get chart_data_balances_path
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end

      it "passes an explicit period through instead of the default" do
        allow(HistoricInvestmentData).to receive(:for).and_call_original
        get chart_data_balances_path, params: {period: "past_month"}
        expect(response).to have_http_status(:success)
        expect(HistoricInvestmentData).to have_received(:for)
          .with(user, period: "past_month")
      end
    end
  end
end
