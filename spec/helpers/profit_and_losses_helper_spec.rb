require "rails_helper"

RSpec.describe ProfitAndLossesHelper, type: :helper do
  let(:account) { double("Account", id: 1) }
  let(:report) { double("AccountReport", account: account, earliest_year: 2020) }

  before do
    helper.instance_variable_set(:@report, report)
    allow(helper).to receive(:params).and_return({})
    allow(helper).to receive(:account_path) do |acc, options = {}|
      period = options[:period] || "past_year"
      "/accounts/#{acc.id}?period=#{period}"
    end
  end

  describe "#account_period_navigation" do
    context "when account is recent (current year)" do
      before do
        allow(Date).to receive(:current).and_return(Date.new(2024, 6, 15))
        allow(report).to receive(:earliest_year).and_return(2024)
      end

      it "returns nil (no buttons shown)" do
        expect(helper.account_period_navigation).to be_nil
      end
    end

    context "when account has few years (≤4 total buttons)" do
      before do
        allow(Date).to receive(:current).and_return(Date.new(2024, 6, 15))
        allow(report).to receive(:earliest_year).and_return(2023)
      end

      it "shows all individual year buttons" do
        html = helper.account_period_navigation
        expect(html).to include('id="profit-and-loss-nav"')
        expect(html).to include('class="chart-toggle"')
        expect(html).to include(">1Y<")
        expect(html).to include(">2024<")
        expect(html).to include(">2023<")
        expect(html).to include(">ALL<")
        expect(html).not_to include("&laquo;")
        expect(html).not_to include("&raquo;")
      end
    end

    context "when account has many years (>4 total buttons)" do
      before do
        allow(Date).to receive(:current).and_return(Date.new(2024, 6, 15))
        allow(report).to receive(:earliest_year).and_return(2020)
        allow(helper).to receive(:params).and_return({period: "2022"})
      end

      it "shows navigation buttons for year 2022" do
        html = helper.account_period_navigation
        expect(html).to include('id="profit-and-loss-nav"')
        expect(html).to include(">1Y<")
        expect(html).to include(">2022<")
        expect(html).to include(">ALL<")
        expect(html).to include("«")  # Previous year button
        expect(html).to include("»")  # Next year button
        expect(html).to include('href="/accounts/1?period=2021"')  # Previous year link
        expect(html).to include('href="/accounts/1?period=2023"')  # Next year link
      end

      it "shows only next button when at earliest year" do
        allow(helper).to receive(:params).and_return({period: "2020"})
        html = helper.account_period_navigation
        expect(html).to include(">2020<")
        expect(html).not_to include("«")  # No previous year button
        expect(html).to include("»")      # Next year button
        expect(html).to include('href="/accounts/1?period=2021"')
      end

      it "shows only previous button when at current year" do
        allow(helper).to receive(:params).and_return({period: "2024"})
        html = helper.account_period_navigation
        expect(html).to include(">2024<")
        expect(html).to include("«")      # Previous year button
        expect(html).not_to include("»")  # No next year button
        expect(html).to include('href="/accounts/1?period=2023"')
      end

      it "defaults to current year when period is not a year" do
        allow(helper).to receive(:params).and_return({period: "past_year"})
        html = helper.account_period_navigation
        expect(html).to include(">2024<")
        expect(html).to include("«")      # Previous year button
        expect(html).not_to include("»")  # No next year button
      end
    end
  end

  describe "#account_period_link" do
    it "creates button for past_year period" do
      html = helper.account_period_link(period: "past_year")
      expect(html).to include(">1Y<")
      expect(html).to include('href="/accounts/1?period=past_year"')
      expect(html).to include('class="btn active"')
    end

    it "creates button for all period" do
      html = helper.account_period_link(period: "all")
      expect(html).to include(">ALL<")
      expect(html).to include('href="/accounts/1?period=all"')
      expect(html).to include('class="btn"')
    end

    it "creates button for year period" do
      html = helper.account_period_link(period: 2023)
      expect(html).to include(">2023<")
      expect(html).to include('href="/accounts/1?period=2023"')
      expect(html).to include('class="btn year"')
    end

    it "marks current period as active" do
      allow(helper).to receive(:params).and_return({period: "2023"})
      html = helper.account_period_link(period: 2023)
      expect(html).to include('class="btn active year"')
    end
  end

  describe "#current_period" do
    it "returns 'past_year' when params[:period] is blank" do
      allow(helper).to receive(:params).and_return({})
      expect(helper.current_period).to eq("past_year")
    end

    it "returns params[:period] when present" do
      allow(helper).to receive(:params).and_return({period: "2023"})
      expect(helper.current_period).to eq("2023")
    end
  end

  describe "#nav_button" do
    it "creates navigation button with symbol" do
      html = helper.nav_button(2023, "«")
      expect(html).to include("«")
      expect(html).to include('href="/accounts/1?period=2023"')
      expect(html).to include('class="btn"')
    end

    it "creates navigation button with raquo symbol" do
      html = helper.nav_button(2025, "»")
      expect(html).to include("»")
      expect(html).to include('href="/accounts/1?period=2025"')
    end
  end
end
