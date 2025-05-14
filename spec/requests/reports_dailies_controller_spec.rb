require "rails_helper"

RSpec.describe Reports::DailiesController, type: :request do
  fixtures :users, :accounts, :balances

  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get reports_dailies_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      before do
        allow_any_instance_of(Reports::DailiesController)
          .to receive(:current_user).and_return(user)
      end

      it "redirects to latest date when no date param" do
        get reports_dailies_path
        expect(response).to redirect_to(
          reports_dailies_path(d: user.balances.latest_date)
        )
      end

      it "redirects to latest date when date param is invalid format" do
        get reports_dailies_path, params: {d: "invalid"}
        expect(response).to redirect_to(
          reports_dailies_path(d: user.balances.latest_date)
        )
      end

      it "redirects to latest date when date param is before earliest_date" do
        get reports_dailies_path, params: {d: user.balances.earliest_date.to_s}
        expect(response).to redirect_to(
          reports_dailies_path(d: user.balances.latest_date)
        )
      end

      it "redirects to latest date when date param is after latest_date" do
        future_date = (user.balances.latest_date + 1.day).to_s
        get reports_dailies_path, params: {d: future_date}
        expect(response).to redirect_to(
          reports_dailies_path(d: user.balances.latest_date)
        )
      end

      it "redirects to latest date when date param is in the future" do
        future = (Date.current + 1.day).to_s
        get reports_dailies_path, params: {d: future}
        expect(response).to redirect_to(
          reports_dailies_path(d: user.balances.latest_date)
        )
      end

      it "returns success when date param is valid" do
        valid_date = user.balances.latest_date.to_s
        get reports_dailies_path, params: {d: valid_date}
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end

      it "invokes DailyReport.for with the correct arguments" do
        valid_date = user.balances.latest_date.to_s
        # Stub a minimal report object to satisfy the view
        report_double = double(
          date: Date.parse(valid_date),
          earliest_date: user.balances.earliest_date,
          latest_date: user.balances.latest_date,
          total: 0,
          todays_exchange_rate: nil,
          day: 0,
          day_usd: 0,
          month: 0,
          month_usd: 0,
          day_exchange_rate: nil,
          month_exchange_rate: nil
        )
        expect(DailyReport).to receive(:for).with(user, valid_date).and_return(report_double)
        get reports_dailies_path, params: {d: valid_date}
      end
    end
  end
end
