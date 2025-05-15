require "rails_helper"

RSpec.describe Charts::ExchangeRatesController, type: :request do
  fixtures :users

  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get chart_data_exchange_rate_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }
      before { allow(CurrencyExchange).to receive(:get_rate_for).and_return(1.0) }

      it "returns a successful JSON response" do
        get chart_data_exchange_rate_path
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end
      context "with period=all" do
        it "returns all rates" do
          older = 2.years.ago.to_date
          newer = 6.months.ago.to_date
          CurrencyRate.create!(currency: "USD", date: older)
          CurrencyRate.create!(currency: "USD", date: newer)

          get chart_data_exchange_rate_path, params: {period: "all"}
          expect(response).to have_http_status(:success)
          parsed = JSON.parse(response.body)
          expect(parsed.size).to eq(2)
          dates = parsed.map { |r| r["date"] }
          expect(dates).to contain_exactly(older.iso8601, newer.iso8601)
        end
      end
      context "with a specific year period" do
        it "returns only rates for that year" do
          in_year = Date.new(2021, 5, 1)
          out_year = Date.new(2020, 12, 31)
          CurrencyRate.create!(currency: "USD", date: in_year)
          CurrencyRate.create!(currency: "USD", date: out_year)

          get chart_data_exchange_rate_path, params: {period: "2021"}
          expect(response).to have_http_status(:success)
          parsed = JSON.parse(response.body)
          expect(parsed.size).to eq(1)
          expect(parsed.first["date"]).to eq(in_year.iso8601)
        end
      end
      context "with invalid period" do
        it "defaults to past_year" do
          start_date = 1.year.ago.to_date
          inside = start_date + 1.day
          outside = start_date - 1.day
          CurrencyRate.create!(currency: "USD", date: inside)
          CurrencyRate.create!(currency: "USD", date: outside)

          get chart_data_exchange_rate_path, params: {period: "invalid"}
          expect(response).to have_http_status(:success)
          parsed = JSON.parse(response.body)
          expect(parsed.size).to eq(1)
          expect(parsed.first["date"]).to eq(inside.iso8601)
        end
      end
    end
  end
end
