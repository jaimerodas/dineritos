require "rails_helper"

RSpec.describe Reports::StatementsController, type: :request do
  fixtures :users, :accounts, :balances

  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get reports_statements_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }

      it "returns a successful response" do
        get reports_statements_path
        expect(response).to have_http_status(:success)
      end

      it "returns HTML content" do
        get reports_statements_path
        expect(response.content_type).to include("text/html")
      end

      it "accepts a period parameter" do
        get reports_statements_path, params: {period: "past_year"}
        expect(response).to have_http_status(:success)
      end

      it "uses current year as default period when none provided" do
        statement_double = double(
          account_lines: [],
          currency_totals: {},
          exchange_rates: [],
          mxn_totals: {starting_balance: 0, final_balance: 0},
          mxn_breakdown: {transferred_mxn: 0, earnings_mxn: 0, transferred_usd_mxn: 0, earnings_usd_mxn: 0, fx_gain_loss: 0},
          multi_day_period?: true,
          period_string: Date.current.year.to_s,
          earliest_date: Date.new(2023, 1, 1)
        )
        expect(Reports::PortfolioStatement).to receive(:new)
          .with(user, Date.current.year.to_s).and_return(statement_double)
        get reports_statements_path
      end

      it "passes custom period to service" do
        statement_double = double(
          account_lines: [],
          currency_totals: {},
          exchange_rates: [],
          mxn_totals: {starting_balance: 0, final_balance: 0},
          mxn_breakdown: {transferred_mxn: 0, earnings_mxn: 0, transferred_usd_mxn: 0, earnings_usd_mxn: 0, fx_gain_loss: 0},
          multi_day_period?: true,
          period_string: "past_year",
          earliest_date: Date.new(2023, 1, 1)
        )
        expect(Reports::PortfolioStatement).to receive(:new)
          .with(user, "past_year").and_return(statement_double)
        get reports_statements_path, params: {period: "past_year"}
      end

      it "renders the statement content" do
        get reports_statements_path
        expect(response.body).to include("Estado de Cuenta")
      end
    end
  end
end
