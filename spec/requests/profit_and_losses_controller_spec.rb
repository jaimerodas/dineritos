require "rails_helper"

RSpec.describe ProfitAndLossesController, type: :request do
  fixtures :users, :accounts

  let(:user) { users(:test_user) }
  let(:account) { accounts(:savings_account) }

  describe "#show" do
    context "when user is logged in" do
      before do
        allow_any_instance_of(ProfitAndLossesController)
          .to receive(:current_user).and_return(user)
        get account_profit_and_loss_path(account)
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "returns HTML content" do
        expect(response.content_type).to include("text/html")
      end
    end

    context "when user is not logged in" do
      before { get account_profit_and_loss_path(account) }

      it "redirects to login page" do
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
