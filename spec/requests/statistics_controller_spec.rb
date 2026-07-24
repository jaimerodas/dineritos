require "rails_helper"

RSpec.describe StatisticsController, type: :request do
  fixtures :users, :accounts

  let(:user) { users(:test_user) }
  let(:account) { accounts(:savings_account) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get account_statistics_path(account)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }

      it "returns http success" do
        get account_statistics_path(account)
        expect(response).to have_http_status(:success)
      end

      it "has html content type" do
        get account_statistics_path(account)
        expect(response.content_type).to include("text/html")
      end

      it "builds the report with the defaults when no params are given" do
        allow(AccountReport).to receive(:new).and_call_original
        get account_statistics_path(account)
        expect(AccountReport).to have_received(:new)
          .with(user: user, account: account, currency: "default", period: "past_year")
      end

      it "passes explicit currency and period through to the report" do
        allow(AccountReport).to receive(:new).and_call_original
        get account_statistics_path(account), params: {currency: "mxn", period: "2023"}
        expect(response).to have_http_status(:success)
        expect(AccountReport).to have_received(:new)
          .with(user: user, account: account, currency: "mxn", period: "2023")
      end
    end
  end
end
