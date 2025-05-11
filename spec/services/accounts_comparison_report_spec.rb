# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountsComparisonReport do
  # Load fixtures
  fixtures :users, :accounts, :balances

  # Access fixtures
  let(:user) { users(:test_user) }
  let(:account1) { accounts(:savings_account) }
  let(:account2) { accounts(:investment_account) }

  # Define dates for test data
  let(:jan_1) { Date.new(2023, 1, 1) }
  let(:jan_15) { Date.new(2023, 1, 15) }
  let(:feb_1) { Date.new(2023, 2, 1) }
  let(:feb_15) { Date.new(2023, 2, 15) }
  let(:mar_1) { Date.new(2023, 3, 1) }

  before do
    # Allow Balance class methods to work with our fixed dates
    allow(Balance).to receive(:earliest_date).and_return(jan_1)
    allow(Balance).to receive(:latest_date).and_return(mar_1)
  end

  describe "#initialize" do
    it "sets user and period" do
      # Mock the period calculation for testing
      freeze_time
      test_period = 1.year.ago..Date.current
      report = described_class.new(user: user, period: "past_year")
      expect(report.period).to be_a(Range)
      expect(report.period).to eq(test_period)
      unfreeze_time
    end

    context "with different period parameters" do
      before do
        # Stub period calculation methods for testing
        travel_to Date.new(2023, 3, 15)
      end

      it "handles 'past_year' period" do
        report = described_class.new(user: user, period: "past_year")

        expect(report.period).to eq(1.year.ago..Date.current)
      end

      it "handles 'past_month' period" do
        report = described_class.new(user: user, period: "past_month")

        expect(report.period).to eq(1.months.ago..Date.current)
      end

      it "handles 'past_week' period" do
        report = described_class.new(user: user, period: "past_week")

        expect(report.period).to eq(1.week.ago..Date.current)
      end

      it "handles numeric year" do
        report = described_class.new(user: user, period: 2023)

        expect(report.period).to be_a(Range)
        expect(report.period).to eq(Date.new(2023, 1, 1)...Date.new(2024, 1, 1))
        expect(report.period).not_to cover(Date.new(2024, 1, 1)) # Exclusive end
      end

      it "handles 'year_to_date'" do
        report = described_class.new(user: user, period: "year_to_date")
        expect(report.period).to eq(Date.new(2023, 1, 1)...Date.new(2024, 1, 1))
        expect(report.period).not_to cover(Date.new(2024, 1, 1)) # Exclusive end
      end

      it "handles 'all' period" do
        report = described_class.new(user: user, period: "all")

        expect(report.period).to eq(jan_1..Date.current)
      end

      after do
        travel_back
      end
    end
  end

  describe "#accounts" do
    context "with a full period" do
      subject do
        # Use a fixed period that includes all our test data
        described_class.new(user: user, period: "all")
      end

      it "returns all accounts with calculated values" do
        # Mock the SQL query result
        mock_accounts = [double(name: "Investment Account"), double(name: "Savings Account")]
        allow(Account).to receive_message_chain(:select, :select, :select, :select, :select, :from, :group, :order).and_return(mock_accounts)

        results = subject.accounts

        # Should return both accounts
        expect(results.size).to eq(2)

        # Verify account names
        expect(results.map(&:name)).to contain_exactly("Savings Account", "Investment Account")
      end

      it "calculates correct balances and changes for each account" do
        results = subject.accounts.to_a

        # Find each account by name for easier testing
        savings = results.find { |a| a.name == "Savings Account" }
        investment = results.find { |a| a.name == "Investment Account" }

        # Verify calculations for savings account
        expect(savings.initial_balance.to_f).to be_within(0.01).of(50.0)  # 5000 cents
        expect(savings.total_transferred.to_f).to be_within(0.01).of(10.0) # 1000 cents additional deposit
        expect(savings.total_earnings.to_f).to be_within(0.01).of(3.0)     # 300 cents total earnings
        expect(savings.final_balance.to_f).to be_within(0.01).of(63.0)    # 6300 cents final balance

        # Verify calculations for investment account
        expect(investment.initial_balance.to_f).to be_within(0.01).of(100.0)   # 10000 cents
        expect(investment.total_transferred.to_f).to be_within(0.01).of(-20.0) # -2000 cents (withdrawal)
        expect(investment.total_earnings.to_f).to be_within(0.01).of(8.0)      # 800 cents total earnings
        expect(investment.final_balance.to_f).to be_within(0.01).of(88.0)     # 8800 cents final balance
      end

      it "orders accounts by name" do
        results = subject.accounts.to_a

        # The Investment account should come before Savings account (alphabetical)
        expect(results.first.name).to eq("Investment Account")
        expect(results.last.name).to eq("Savings Account")
      end
    end

    context "with a partial period" do
      before do
        travel_to Date.new(2023, 2, 1)
      end
      subject do
        # Use a period that only includes January and February
        described_class.new(user: user, period: "past_year")
      end

      it "only includes balances within the specified period" do
        results = subject.accounts.to_a

        savings = results.find { |a| a.name == "Savings Account" }
        investment = results.find { |a| a.name == "Investment Account" }

        # The final balances should reflect February, not March
        expect(savings.final_balance.to_f).to be_within(0.01).of(62.0)     # 6200 cents as of Feb 1
        expect(investment.final_balance.to_f).to be_within(0.01).of(105.0) # 10500 cents as of Feb 1
      end

      after do
        travel_back
      end
    end
  end

  describe "#totals" do
    subject do
      described_class.new(user: user, period: "all")
    end

    it "calculates combined totals across all accounts" do
      totals = subject.totals

      # Verify total calculations
      # Combined final balance: 63.0 + 88.0 = 151.00
      expect(totals[:balance].to_f).to be_within(0.01).of(151.0)

      # Combined earnings: 3.0 + 8.0 = 11.00
      expect(totals[:earnings].to_f).to be_within(0.01).of(11.0)

      # Combined transfers: 10.0 + (-20.0) = -10.0
      expect(totals[:transfers].to_f).to be_within(0.01).of(-10.0)
    end

    it "handles accounts with no balances" do
      # Create an empty account
      user.accounts.create!(name: "Empty Account", currency: "MXN")

      # Totals should still match the existing accounts (empty account adds nothing)
      totals = subject.totals
      expect(totals[:balance].to_f).to be_within(0.01).of(151.0)
      expect(totals[:earnings].to_f).to be_within(0.01).of(11.0)
      expect(totals[:transfers].to_f).to be_within(0.01).of(-10.0)
    end
  end
end
