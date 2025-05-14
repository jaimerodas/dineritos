# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvestmentSummary do
  # Load fixtures
  fixtures :users, :accounts, :balances

  # Access fixtures
  let(:user) { users(:test_user) }

  # Define test dates
  let(:jan_1) { Date.new(2022, 1, 1) }
  let(:feb_1) { Date.new(2023, 2, 1) }
  let(:mar_1) { Date.new(2023, 3, 1) }

  describe "#initialize" do
    it "sets user and period from parameters" do
      summary = described_class.for(user: user, period: "past_year")

      expect(summary.user).to eq(user)
      expect(summary.period).to be_a(Range)
    end

    it "handles different period strings" do
      travel_to Date.new(2023, 3, 15)

      # Test 'past_year' period
      past_year_summary = described_class.for(user: user, period: "past_year")
      expect(past_year_summary.period).to be_a(Range)
      expect(past_year_summary.period).to cover(Date.new(2022, 3, 15))

      # Test 'all' period
      allow(Balance).to receive(:earliest_date).and_return(jan_1)
      all_summary = described_class.for(user: user, period: "all")
      expect(all_summary.period).to be_a(Range)
      expect(all_summary.period).to cover(jan_1)

      # Test numeric year
      year_summary = described_class.for(user: user, period: "2023")
      expect(year_summary.period).to be_a(Range)
      expect(year_summary.period).to cover(Date.new(2023, 6, 15))
      expect(year_summary.period).not_to cover(Date.new(2024, 1, 1))

      travel_back
    end
  end

  describe "with test investment data" do
    # Create a fresh user with accounts and balances for investment tracking
    let(:investment_user) { User.create!(email: "investment_test@example.com") }
    let(:account1) { investment_user.accounts.create!(name: "Investment 1", currency: "MXN") }
    let(:account2) { investment_user.accounts.create!(name: "Investment 2", currency: "MXN") }

    before do
      travel_to Date.new(2023, 3, 15)

      # Account 1 balances
      # January 1: Initial deposit of 10,000
      Balance.create!(
        account: account1,
        date: jan_1,
        amount_cents: 10_000_00,
        transfers_cents: 10_000_00,
        currency: "MXN"
      )

      # February 1: Growth to 10,500 (earnings of 500)
      Balance.create!(
        account: account1,
        date: feb_1,
        amount_cents: 10_500_00,
        transfers_cents: 0,
        currency: "MXN"
      )

      # March 1: Additional deposit of 5,000, growth to 16,000 (earnings of 500)
      Balance.create!(
        account: account1,
        date: mar_1,
        amount_cents: 16_000_00,
        transfers_cents: 5_000_00,
        currency: "MXN"
      )

      # Account 2 balances
      # January 1: Initial deposit of 5,000
      Balance.create!(
        account: account2,
        date: jan_1,
        amount_cents: 5_000_00,
        transfers_cents: 5_000_00,
        currency: "MXN"
      )

      # February 1: Growth to 5,300 (earnings of 300)
      Balance.create!(
        account: account2,
        date: feb_1,
        amount_cents: 5_300_00,
        transfers_cents: 0,
        currency: "MXN"
      )

      # March 1: Withdrawal of 1,000, growth to 4,500 (earnings of 200)
      Balance.create!(
        account: account2,
        date: mar_1,
        amount_cents: 4_500_00,
        transfers_cents: -1_000_00,
        currency: "MXN"
      )
    end

    after do
      travel_back
    end

    describe "#final_balance" do
      it "returns the sum of final balances across all accounts" do
        summary = described_class.for(user: investment_user, period: "all")

        # Final balances: 16,000 + 4,500 = 20,500
        expect(summary.final_balance).to eq(BigDecimal("20500.0"))
      end

      it "returns correct balance for a specific time period" do
        last_year_summary = described_class.for(user: investment_user, period: "2022")

        # Feb balances: 10,500 + 5,300 = 15,800
        expect(last_year_summary.final_balance).to eq(BigDecimal("15000.0"))
      end
    end

    describe "#deposits" do
      it "returns the sum of all deposits in the period" do
        summary = described_class.for(user: investment_user, period: "all")

        # Deposits: 10,000 + 5,000 + 5,000 = 20,000
        expect(summary.deposits).to eq(BigDecimal("20000.0"))
      end
    end

    describe "#withdrawals" do
      it "returns the absolute sum of all withdrawals in the period" do
        summary = described_class.for(user: investment_user, period: "all")

        # Withdrawals: 1,000 (as positive value)
        expect(summary.withdrawals).to eq(BigDecimal("1000.0"))
      end
    end

    describe "#earnings" do
      it "returns the total earnings in the period" do
        summary = described_class.for(user: investment_user, period: "all")

        # Earnings: 500 + 500 + 300 + 200 = 1,500
        expect(summary.earnings).to eq(BigDecimal("1500.0"))
      end
    end

    describe "#net_investment" do
      it "calculates the net investment (deposits - withdrawals)" do
        summary = described_class.for(user: investment_user, period: "all")

        # Net investment: 20,000 - 1,000 = 19,000
        expect(summary.net_investment).to eq(BigDecimal("19000.0"))
      end
    end

    describe "#starting_balance" do
      it "calculates the starting balance based on final balance, earnings, and net investment" do
        summary = described_class.for(user: investment_user, period: "all")

        # Starting balance: 20,500 - 1,500 - 19,000 = 0
        expect(summary.starting_balance).to eq(BigDecimal("0.0"))
      end

      it "calculates non-zero starting balance for partial periods" do
        # Create a summary for just March
        mar_summary = described_class.for(user: investment_user, period: "2023-03-01")

        # Starting balance in March: Final feb balance = 15,800
        expected_starting = mar_summary.final_balance - mar_summary.earnings - mar_summary.net_investment
        expect(mar_summary.starting_balance).to eq(expected_starting)
      end
    end

    describe "#to_h" do
      it "returns a hash with all summary data" do
        summary = described_class.for(user: investment_user, period: "all").to_h

        expect(summary).to be_a(Hash)

        # Check all expected keys
        expected_keys = [:starting_balance, :final_balance, :earnings,
          :deposits, :withdrawals, :net_investment, :irr]
        expect(summary.keys).to match_array(expected_keys)

        # Check values (converted to floats)
        expect(summary[:final_balance]).to eq(20500.0)
        expect(summary[:earnings]).to eq(1500.0)
        expect(summary[:deposits]).to eq(20000.0)
        expect(summary[:withdrawals]).to eq(1000.0)
        expect(summary[:net_investment]).to eq(19000.0)
        expect(summary[:starting_balance]).to eq(0.0)
        expect(summary[:irr]).to be_within(0.0001).of(0.0869)
      end
    end

    describe "#earliest_year" do
      it "returns the year for the earliest balance" do
        allow(Balance).to receive(:earliest_date).and_return(jan_1)
        earliest_year = described_class.for(user: investment_user, period: "all").earliest_year
        expect(earliest_year).to eq(2022)
      end
    end
  end

  describe "with edge cases" do
    let(:edge_user) { User.create!(email: "edge_case_test@example.com") }

    context "with no accounts" do
      it "returns zero for all financial metrics" do
        summary = described_class.for(user: edge_user, period: "all")

        # All metrics should be zero with no data
        expect(summary.final_balance).to eq(0)
        expect(summary.earnings).to eq(0)
        expect(summary.deposits).to eq(0)
        expect(summary.withdrawals).to eq(0)
        expect(summary.net_investment).to eq(0)
        expect(summary.starting_balance).to eq(0)
      end
    end

    context "with accounts but no balances" do
      before do
        edge_user.accounts.create!(name: "Empty Account", currency: "MXN")
      end

      it "returns zero for all financial metrics" do
        summary = described_class.for(user: edge_user, period: "all")

        # All metrics should be zero with no balance data
        expect(summary.final_balance).to eq(0)
        expect(summary.earnings).to eq(0)
        expect(summary.deposits).to eq(0)
        expect(summary.withdrawals).to eq(0)
        expect(summary.net_investment).to eq(0)
        expect(summary.starting_balance).to eq(0)
      end
    end

    context "with USD accounts" do
      before do
        # Create MXN and USD accounts
        mxn_account = edge_user.accounts.create!(name: "MXN Account", currency: "MXN")
        usd_account = edge_user.accounts.create!(name: "USD Account", currency: "USD")

        # Add MXN balance
        Balance.create!(account: mxn_account, date: Date.yesterday, amount_cents: 5_000_00)
        Balance.create!(
          account: mxn_account,
          date: Date.current,
          amount_cents: 10_000_00,
          transfers_cents: 4_000_00
        )

        # Add USD balance - should be converted into MXN for calculations
        Balance.create!(
          account: usd_account,
          date: Date.yesterday,
          amount_cents: 300_00,
          currency: "USD"
        )
        Balance.create!(
          account: usd_account,
          date: Date.current,
          amount_cents: 500_00,
          transfers_cents: 100_00,
          currency: "USD"
        )
      end

      it "converts USD to MXN in calculations" do
        summary = described_class.for(user: edge_user, period: "all")
        # Should only reflect MXN balances
        # 10,000 + (500 * 20) = 20,000
        expect(summary.final_balance).to eq(BigDecimal("20000.0"))
        # 4,000 + (100 * 20) = 6,000
        expect(summary.deposits).to eq(BigDecimal("6000.0"))
        # 1,000 + (100 * 20) = 3,000
        expect(summary.earnings).to eq(BigDecimal("3000.0"))
      end
    end
  end
end
