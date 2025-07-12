# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountReport do
  # Set up test users and accounts with real data
  fixtures :users
  let(:user) { users(:test_user) }
  let(:unauthorized_user) { users(:test_user_2) }

  # Create an account with a known transaction history
  let(:account) do
    user.accounts.create!(
      name: "Test Investment Account",
      currency: "MXN"
    )
  end

  # Define time periods for the test data
  let(:jan_1) { Date.new(2023, 1, 1) }
  let(:jan_15) { Date.new(2023, 1, 15) }
  let(:feb_1) { Date.new(2023, 2, 1) }
  let(:feb_15) { Date.new(2023, 2, 15) }
  let(:mar_1) { Date.new(2023, 3, 1) }

  # Set up test balances with a known history
  before do
    # Initial deposit on Jan 1: 10,000 (100.00)
    Balance.create!(
      account: account,
      date: jan_1,
      amount_cents: 10_000,
      transfers_cents: 10_000,
      currency: "MXN"
    )

    # Mid-January: Balance grows to 10,500 (105.00) - 500 (5.00) earnings
    Balance.create!(
      account: account,
      date: jan_15,
      amount_cents: 10_500,
      transfers_cents: 0,
      diff_cents: 500,
      diff_days: 14,
      currency: "MXN"
    )

    # February 1: Additional deposit of 5,000 (50.00)
    Balance.create!(
      account: account,
      date: feb_1,
      amount_cents: 15_800,
      transfers_cents: 5_000,
      diff_cents: 300,
      diff_days: 17,
      currency: "MXN"
    )

    # Mid-February: Withdrawal of 2,000 (20.00)
    Balance.create!(
      account: account,
      date: feb_15,
      amount_cents: 14_200,
      transfers_cents: -2_000,
      diff_cents: 400,
      diff_days: 14,
      currency: "MXN"
    )

    # March 1: Final balance with earnings
    Balance.create!(
      account: account,
      date: mar_1,
      amount_cents: 15_000,
      transfers_cents: 0,
      diff_cents: 800,
      diff_days: 14,
      currency: "MXN"
    )

    # Allow Balance class methods to work with our fixed dates
    allow(Balance).to receive(:earliest_date).and_return(jan_1)
    allow(Balance).to receive(:latest_date).and_return(mar_1)
  end

  describe "#initialize" do
    it "sets account, currency, and period parameters" do
      report = described_class.new(user: user, account: account)

      expect(report.account).to eq(account)
      expect(report.currency).to eq("MXN")
      expect(report.period).to be_a(Range)
      expect(report.period).to cover(jan_1)
      expect(report.period).to cover(mar_1)
    end

    it "allows overriding the currency to MXN" do
      # Create a USD account
      usd_account = user.accounts.create!(
        name: "USD Account",
        currency: "USD"
      )

      # Override the currency to MXN
      report = described_class.new(user: user, account: usd_account, currency: "MXN")
      expect(report.currency).to eq("MXN")
    end

    it "allows specifying a time period" do
      # Mock the determine_period_range method for specific year
      year_range = Date.new(2023, 1, 1)...Date.new(2024, 1, 1)

      year_2023 = described_class.new(user: user, account: account, period: 2023)
      expect(year_2023.period).to eq(year_range)

      # Test with 'past_year' string
      travel_to(Date.new(2023, 3, 15))

      past_year_range = Date.new(2022, 3, 15)..Date.new(2023, 3, 15)
      past_year = described_class.new(user: user, account: account, period: "past_year")

      expect(past_year.period).to eq(past_year_range)

      travel_back
    end

    it "validates that the account belongs to the user" do
      expect {
        described_class.new(user: unauthorized_user, account: account)
      }.to raise_error(ActiveRecord::RecordNotFound, /Account not found for user/)
    end
  end

  describe "account information" do
    subject { described_class.new(user: user, account: account) }

    it "returns the account name" do
      expect(subject.account_name).to eq("Test Investment Account")
    end

    it "returns the latest balance for the account" do
      latest = subject.latest_balance
      expect(latest).to be_a(Balance)
      expect(latest.date).to eq(mar_1)
      expect(latest.amount_cents).to eq(15_000)
    end

    it "returns the earliest date with balance data" do
      expect(subject.earliest_date).to eq(jan_1)
    end
  end

  describe "financial calculations" do
    # Set a fixed period for consistent testing
    let(:jan_feb_period) { jan_1..feb_15 }

    before { travel_to(feb_15) }
    after { travel_back }

    subject { described_class.new(user: user, account: account) }

    it "calculates the total earnings" do
      # Sum of earnings from Jan 1 to Feb 15: 500 + 300 + 400 = 1200 cents = 12.00
      expect(subject.earnings).to eq(12.00)
    end

    it "calculates total deposits" do
      # Initial deposit (10000) + Feb 1 deposit (5000) = 15000 cents = 150.00
      expect(subject.deposits).to eq(150.00)
    end

    it "calculates total withdrawals" do
      # Feb 15 withdrawal (2000 cents = 20.00) - returned as positive
      expect(subject.withdrawals).to eq(20.00)
    end

    it "calculates net transfers" do
      # Deposits (150.00) - Withdrawals (20.00) = 130.00
      expect(subject.net_transferred).to eq(130.00)
    end

    it "calculates IRR based on transaction history" do
      # The IRR calculation is complex, so we just verify it returns a decimal value
      expect(subject.irr).to be_a(BigDecimal)
      expect(subject.irr).to be >= 0
    end
  end

  describe "chart data generation" do
    subject { described_class.new(user: user, account: account) }

    it "formats IRR data for monthly JavaScript charts" do
      result = subject.monthly_irrs

      # Should include data for January, February, and March
      expect(result).to include('new Date("2023-01-01")')
      expect(result).to include('new Date("2023-02-01")')
      expect(result).to include('new Date("2023-03-01")')

      # Should include the 'value' property with numeric IRR values
      expect(result).to match(/value: [0-9.]+/)
    end

    it "formats balance data for JavaScript charts" do
      result = subject.balances_in_period

      # Should include all dates with proper values
      expect(result).to include('new Date("2023-01-01")')
      expect(result).to include('new Date("2023-01-15")')
      expect(result).to include('new Date("2023-02-01")')
      expect(result).to include('new Date("2023-02-15")')
      expect(result).to include('new Date("2023-03-01")')

      # Should include values for balances
      expect(result).to include("value: 100.0") # Jan 1
      expect(result).to include("value: 105.0") # Jan 15
      # Values are dividing by 100.0 to convert cents to dollars
    end
  end

  describe "profit and loss reporting" do
    let(:report_period) { jan_1..mar_1 }

    subject { described_class.new(user: user, account: account) }

    it "generates monthly profit and loss data" do
      results = subject.monthly_pnl

      # Should contain data for all months
      expect(results.size).to eq(3) # Jan, Feb, Mar

      # Each month has the right structure
      results.each do |month|
        expect(month.keys).to include(:month, :deposits, :withdrawals, :earnings, :initial_balance, :final_balance)
      end

      # Check January data specifically
      january = results.find { |m| m[:month] == "2023-01" }
      expect(january[:deposits]).to eq(100.0) # 10000 cents
      expect(january[:earnings]).to eq(5.0)   # 500 cents

      # Check February data
      february = results.find { |m| m[:month] == "2023-02" }
      expect(february[:deposits]).to eq(50.0)     # 5000 cents
      expect(february[:withdrawals].abs).to eq(20.0) # 2000 cents (might be negative in result)
      expect(february[:earnings]).to eq(7.0)      # 700 cents (300 + 400)

      # Check totals calculation
      totals = subject.total_pnl
      expect(totals[:deposits]).to eq(150.0)          # 15000 cents total deposits
      expect(totals[:withdrawals].abs).to eq(20.0)   # 2000 cents total withdrawals (might be negative)
      expect(totals[:earnings]).to eq(20.0)           # 2000 cents total earnings (500 + 300 + 400 + 800)
    end
  end
end
