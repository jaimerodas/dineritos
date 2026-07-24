# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountsHelper, type: :helper do
  let(:account) { double("Account", id: 7, currency: "MXN") }
  let(:report) { double("Report", account: account, period_text: "past_year", earliest_year: 2020) }

  before do
    helper.instance_variable_set(:@report, report)
    allow(helper).to receive(:params).and_return({})
  end

  describe "#account_period_title" do
    it "translates past_year" do
      allow(report).to receive(:period_text).and_return("past_year")
      expect(helper.account_period_title).to eq("Último año")
    end

    it "renders a year span for the all period" do
      travel_to Date.new(2024, 6, 15) do
        allow(report).to receive(:period_text).and_return("all")
        expect(helper.account_period_title).to eq("2020-2024")
      end
    end

    it "falls back to the raw period text" do
      allow(report).to receive(:period_text).and_return("2023")
      expect(helper.account_period_title).to eq("2023")
    end
  end

  describe "#period_buttons" do
    it "renders a button for every period" do
      html = helper.period_buttons
      expect(html).to include("chart-toggle")
      expect(html).to include(">1W<", ">1M<", ">1Y<", ">YTD<")
    end
  end

  describe "#period_button" do
    it "marks the button active when it matches the current period" do
      allow(helper).to receive(:params).and_return({period: "past_month"})
      expect(helper.period_button("1M", "past_month")).to include('class="btn active"')
    end

    it "leaves other buttons inactive" do
      allow(helper).to receive(:params).and_return({period: "past_month"})
      expect(helper.period_button("1W", "past_week")).to include('class="btn"')
    end

    it "defaults to the controller default period when none is given" do
      expect(helper.period_button("1Y", "past_year")).to include('class="btn active"')
    end
  end

  describe "#should_be_shown?" do
    it "is false when the account has no balance, earnings or transfers" do
      expect(helper.should_be_shown?(
        double(final_balance: 0, total_earnings: 0, total_transferred: 0)
      )).to be false
    end

    it "is true when the account still holds a balance" do
      expect(helper.should_be_shown?(
        double(final_balance: 100, total_earnings: 0, total_transferred: 0)
      )).to be true
    end

    it "is true when the account had earnings but nets out to zero" do
      expect(helper.should_be_shown?(
        double(final_balance: 0, total_earnings: 50, total_transferred: 0)
      )).to be true
    end

    it "is true when the account had transfers but nets out to zero" do
      expect(helper.should_be_shown?(
        double(final_balance: 0, total_earnings: 0, total_transferred: -50)
      )).to be true
    end
  end

  describe "#account_currency_toggle" do
    context "when the account is already in MXN" do
      it "renders nothing" do
        expect(helper.account_currency_toggle).to be_nil
      end
    end

    context "when the account is in USD and viewed in its own currency" do
      let(:account) { double("Account", id: 7, currency: "USD") }

      it "reports USD and offers a link to MXN" do
        html = helper.account_currency_toggle
        expect(html).to include("Datos en USD.")
        expect(html).to include("Ver en MXN")
        expect(html).to include("currency=mxn")
      end

      it "treats an explicit default currency the same as a blank one" do
        allow(helper).to receive(:params).and_return({currency: "default"})
        expect(helper.account_currency_toggle).to include("Datos en USD.")
      end
    end

    context "when the account is in USD and viewed in MXN" do
      let(:account) { double("Account", id: 7, currency: "USD") }

      before { allow(helper).to receive(:params).and_return({currency: "mxn"}) }

      it "reports MXN and offers a link back to USD" do
        html = helper.account_currency_toggle
        expect(html).to include("Datos en MXN.")
        expect(html).to include("Ver en USD")
        expect(html).to include("currency=default")
      end
    end
  end
end
