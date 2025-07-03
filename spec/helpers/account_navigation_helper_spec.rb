require "rails_helper"

RSpec.describe AccountNavigationHelper, type: :helper do
  let(:account) { double("Account", id: 1, new_and_empty?: false) }
  let(:report) { double("Report", account: account, earliest_year: 2020) }

  before do
    helper.instance_variable_set(:@report, report)
    helper.instance_variable_set(:@account, account)
    allow(helper).to receive(:params).and_return({})

    # Stub path helpers
    allow(helper).to receive(:account_path) do |acc, options = {}|
      period = options[:period] || "past_year"
      "/accounts/#{acc.id}?period=#{period}"
    end
    allow(helper).to receive(:account_movements_path) do |*args|
      acc = args[0] || account
      params = args[1] || {}
      "/accounts/#{acc.id}/movements?#{params.to_query}"
    end
    allow(helper).to receive(:account_statistics_path) { |acc| "/accounts/#{acc.id}/statistics" }
    allow(helper).to receive(:edit_account_path) { |acc| "/accounts/#{acc.id}/edit" }
    allow(helper).to receive(:l) do |date, format:|
      case format
      when :numeric_month then date.strftime("%Y-%m")
      when :month then date.strftime("%B")
      else date.to_s
      end
    end
  end

  # Period navigation tests (from profit_and_losses_helper)
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

    context "when account has few years (≤1 year span)" do
      before do
        allow(Date).to receive(:current).and_return(Date.new(2024, 6, 15))
        allow(report).to receive(:earliest_year).and_return(2023) # 1 year span
        allow(helper).to receive(:params).and_return({period: "2023"})
      end

      it "shows all individual year buttons" do
        html = helper.account_period_navigation
        expect(html).to include('id="profit-and-loss-nav"')
        expect(html).to include(">1Y<")
        expect(html).to include(">2023<")
        expect(html).to include(">2024<")
        expect(html).to include(">ALL<")
      end
    end

    context "when account has many years (navigation mode)" do
      before do
        allow(Date).to receive(:current).and_return(Date.new(2024, 6, 15))
        allow(report).to receive(:earliest_year).and_return(2018) # More than 3 years span
        allow(helper).to receive(:params).and_return({period: "2022"})
      end

      it "shows navigation buttons with arrows" do
        html = helper.account_period_navigation
        expect(html).to include('id="profit-and-loss-nav"')
        expect(html).to include(">1Y<")
        expect(html).to include(">2022<")
        expect(html).to include(">ALL<")
        expect(html).to include("«")  # Previous year button
        expect(html).to include("»")  # Next year button
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
    end
  end

  # Month navigation tests (from account_movements_helper)
  describe "#account_month_navigation" do
    context "when both prev and next months exist" do
      before do
        allow(report).to receive(:prev_month).and_return(Date.new(2023, 1, 1))
        allow(report).to receive(:next_month).and_return(Date.new(2023, 3, 1))
      end

      it "shows both navigation links" do
        html = helper.account_month_navigation
        expect(html).to include('class="chart-toggle"')
        expect(html).to include("January")
        expect(html).to include("March")
        expect(html).to include('class="btn"')
      end
    end

    context "when no prev or next months" do
      before do
        allow(report).to receive(:prev_month).and_return(nil)
        allow(report).to receive(:next_month).and_return(nil)
      end

      it "returns nil" do
        expect(helper.account_month_navigation).to be_nil
      end
    end
  end

  describe "#prev_month_link" do
    context "when prev_month exists" do
      let(:prev_date) { Date.new(2023, 1, 1) }

      before do
        allow(report).to receive(:prev_month).and_return(prev_date)
      end

      it "returns a link to the previous month" do
        html = helper.prev_month_link
        expect(html).to include('href="/accounts/1/movements?month=2023-01"')
        expect(html).to include("January")
        expect(html).to include('class="btn"')
      end
    end

    context "when prev_month is nil" do
      before do
        allow(report).to receive(:prev_month).and_return(nil)
      end

      it "returns nil when no previous month" do
        html = helper.prev_month_link
        expect(html).to be_nil
      end
    end
  end

  describe "#next_month_link" do
    context "when next_month exists" do
      let(:next_date) { Date.new(2023, 3, 1) }

      before do
        allow(report).to receive(:next_month).and_return(next_date)
      end

      it "returns a link to the next month" do
        html = helper.next_month_link
        expect(html).to include('href="/accounts/1/movements?month=2023-03"')
        expect(html).to include("March")
        expect(html).to include('class="btn"')
      end
    end

    context "when next_month is nil" do
      before do
        allow(report).to receive(:next_month).and_return(nil)
      end

      it "returns nil when no next month" do
        html = helper.next_month_link
        expect(html).to be_nil
      end
    end
  end

  describe "#month_link" do
    let(:date) { Date.new(2023, 2, 1) }

    context "when date is present" do
      it "returns a link with formatted date" do
        html = helper.month_link(date)
        expect(html).to include('href="/accounts/1/movements?month=2023-02"')
        expect(html).to include("February")
        expect(html).to include('class="btn"')
      end
    end

    context "when date is nil" do
      it "returns nil" do
        html = helper.month_link(nil)
        expect(html).to be_nil
      end
    end
  end

  # Account navigation tests
  describe "#account_main_nav" do
    context "when account is new and empty" do
      before do
        allow(account).to receive(:new_and_empty?).and_return(true)
      end

      it "returns simplified navigation" do
        html = helper.account_main_nav(current: "Resumen")
        expect(html).to include('data-account-header-target="nav"')
        expect(html).to include("Resumen")
        expect(html).to include("Opciones")
        expect(html).not_to include("Detalle")
        expect(html).not_to include("Estadísticas")
      end
    end

    context "when account is not new and empty" do
      before do
        allow(account).to receive(:new_and_empty?).and_return(false)
      end

      it "returns full navigation menu" do
        html = helper.account_main_nav(current: "Resumen")
        expect(html).to include('data-account-header-target="nav"')
        expect(html).to include("Resumen")
        expect(html).to include("Detalle")
        expect(html).to include("Estadísticas")
        expect(html).to include("Opciones")
      end
    end
  end
end
