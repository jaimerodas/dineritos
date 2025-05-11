# frozen_string_literal: true

require "rails_helper"

RSpec.describe IrrReport do
  # Load fixtures
  fixtures :users, :accounts, :balances

  # Access fixtures
  let(:user) { users(:test_user) }

  # Define test dates
  let(:jan_1) { Date.new(2023, 1, 1) }
  let(:feb_1) { Date.new(2023, 2, 1) }
  let(:mar_1) { Date.new(2023, 3, 1) }

  describe "#initialize" do
    it "sets user and period from parameters" do
      report = described_class.for(user: user, period: "past_year")

      expect(report.user).to eq(user)
      expect(report.period).to be_a(Range)
    end

    it "handles different period strings" do
      travel_to Date.new(2023, 3, 15)

      # Test 'past_year' period
      past_year_report = described_class.for(user: user, period: "past_year")
      expect(past_year_report.period).to be_a(Range)
      expect(past_year_report.period).to cover(Date.new(2022, 4, 1))

      # Test 'all' period
      all_report = described_class.for(user: user, period: "all")
      expect(all_report.period).to be_a(Range)
      expect(all_report.period).to cover(Balance.earliest_date)

      # Test numeric year
      year_report = described_class.for(user: user, period: "2023")
      expect(year_report.period).to be_a(Range)
      expect(year_report.period).to cover(Date.new(2023, 12, 15))
      expect(year_report.period).not_to cover(Date.new(2024, 1, 1))

      travel_back
    end
  end

  describe "#calculate_period_from" do
    subject { described_class.for(user: user) }

    it "returns correct range for 'past_year'" do
      travel_to Date.new(2023, 3, 15)

      period = subject.send(:calculate_period_from, "past_year")

      expected_start = Date.new(2022, 3, 3) # 1 year ago beginning of month minus 1 month
      expect(period).to be_a(Range)
      expect(period).to cover(expected_start)
      expect(period).to cover(Date.current)

      travel_back
    end

    it "returns correct range for 'all'" do
      allow(Balance).to receive(:earliest_date).and_return(jan_1)

      period = subject.send(:calculate_period_from, "all")

      expect(period).to be_a(Range)
      expect(period).to cover(jan_1)
      expect(period).to cover(Date.current)
    end

    it "returns correct range for numeric year" do
      period = subject.send(:calculate_period_from, "2023")

      expect(period).to be_a(Range)
      expect(period).to cover(Date.new(2023, 1, 1))
      expect(period).not_to cover(Date.new(2024, 1, 1))
    end
  end

  describe "with test balances" do
    # Create a user with accounts and balances designed for IRR calculation
    let(:test_irr_user) { User.create!(email: "irr_test@example.com") }
    let(:account) { test_irr_user.accounts.create!(name: "IRR Test Account", currency: "MXN") }

    before do
      # January 1: Initial deposit 10,000
      Balance.create!(
        account: account,
        date: jan_1,
        amount_cents: 10_000_00,
        transfers_cents: 10_000_00,
        diff_cents: 0,
        currency: "MXN"
      )

      # February 1: Balance grows to 10,300 (300 earnings, no new transfers)
      Balance.create!(
        account: account,
        date: feb_1,
        amount_cents: 10_300_00,
        transfers_cents: 0,
        diff_cents: 300_00,
        diff_days: 31,
        currency: "MXN"
      )

      # March 1: Additional deposit of 5,000, earnings of 400
      Balance.create!(
        account: account,
        date: mar_1,
        amount_cents: 15_700_00,
        transfers_cents: 5_000_00,
        diff_cents: 400_00,
        diff_days: 28,
        currency: "MXN"
      )
    end

    describe "#by_month" do
      it "calculates monthly IRR data" do
        # Use fixed date for consistent results
        travel_to Date.new(2023, 3, 15)

        report = described_class.for(user: test_irr_user, period: "all")
        result = report.by_month

        expect(result).to be_a(Hash)
        expect(result.keys).to match_array([feb_1.to_s, mar_1.to_s])

        # February calculation
        feb = result[feb_1.to_s]
        expect(feb[:diff]).to eq(300.0)
        expect(feb[:starting_balance]).to eq(10_000.0)
        expect(feb[:transfers]).to eq(0.0)
        expect(feb[:days]).to eq(28)

        # March calculation
        mar = result[mar_1.to_s]
        expect(mar[:diff]).to eq(400.0)
        expect(mar[:starting_balance]).to eq(10_300.0)
        expect(mar[:transfers]).to eq(5_000.0)
        expect(mar[:days]).to eq(15)

        travel_back
      end

      it "calculates IRR correctly for each month" do
        travel_to Date.new(2023, 3, 15)

        report = described_class.for(user: test_irr_user, period: "all")
        result = report.by_month

        # February IRR: (1 + 300/10_000)^(365/28) - 1
        feb_expected_irr = ((1 + 300.0 / 10_000.0)**(365.0 / 28.0)) - 1
        expect(result[feb_1.to_s][:irr]).to be_within(0.0001).of(feb_expected_irr)

        # March IRR: (1 + 400_00/10_300_00)^(365/15) - 1
        mar_expected_irr = ((1 + 400.0 / 10_300.0)**(365.0 / 15.0)) - 1
        expect(result[mar_1.to_s][:irr]).to be_within(0.0001).of(mar_expected_irr)

        travel_back
      end
    end

    describe "#accumulated_irr" do
      it "calculates the accumulated IRR across all months" do
        travel_to Date.new(2023, 3, 15)

        report = described_class.for(user: test_irr_user, period: "all")
        irr = report.accumulated_irr

        # Total rate calculation: (300/10_000 + 400/10_300)
        # Total days: 28 + 15 = 43
        # Accumulated IRR: (1 + rate)^(365/days) - 1
        expected_rate = ((1 + (300.0 / 10_000.0 + 400.0 / 10_300.0))**(365.0 / 43.0)) - 1
        expect(irr).to be_within(0.0001).of(expected_rate)

        travel_back
      end
    end

    describe "edge cases" do
      it "handles a single month of data" do
        # Create a user with only one month of balance data
        single_user = User.create!(email: "single_month@example.com")
        single_account = single_user.accounts.create!(name: "Single Month Account", currency: "MXN")

        Balance.create!(
          account: single_account,
          date: jan_1,
          amount_cents: 10_000_00,
          transfers_cents: 10_000_00,
          diff_cents: 0,
          currency: "MXN"
        )

        report = described_class.for(user: single_user, period: "all")

        # by_month requires two consecutive months to calculate
        expect(report.by_month).to be_empty

        # accumulated_irr should handle empty by_month
        expect(report.accumulated_irr).to eq(0)
      end
    end
  end
end
