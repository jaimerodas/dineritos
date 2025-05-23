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

  describe "#initialize" do
    it "sets user and period" do
      # Mock the period calculation for testing
      freeze_time
      report = described_class.new(user: user, period: "past_year")
      expect(report.period).to be_a(Range)
      expect(report.user).to eq(user)
      unfreeze_time
    end

    context "with different period parameters" do
      before { travel_to Date.new(2023, 3, 15) }
      after { travel_back }

      it "handles 'past_year' period" do
        report = described_class.new(user: user, period: "past_year")
        test_period = 1.year.ago.to_date..Date.current

        expect(report.period).to eq(test_period)
      end

      it "handles 'past_month' period" do
        report = described_class.new(user: user, period: "past_month")

        expect(report.period).to eq(1.months.ago.to_date..Date.current)
      end

      it "handles 'past_week' period" do
        report = described_class.new(user: user, period: "past_week")

        expect(report.period).to eq(1.week.ago.to_date..Date.current)
      end

      it "handles numeric year" do
        report = described_class.new(user: user, period: 2022)

        expect(report.period).to be_a(Range)
        expect(report.period).to eq(Date.new(2022, 1, 1)...Date.new(2023, 1, 1))
        expect(report.period).not_to cover(Date.new(2023, 1, 1)) # Exclusive end
      end

      it "handles 'year_to_date'" do
        report = described_class.new(user: user, period: "year_to_date")
        expect(report.period).to eq(Date.new(2023, 1, 1)..Date.current)
        expect(report.period).not_to cover(Date.current + 1.day) # Exclusive end
      end

      it "handles 'all' period" do
        report = described_class.new(user: user, period: "all")

        expect(report.period).to eq(jan_1..Date.current)
      end
    end
  end

  describe "#accounts" do
    context "with a full period" do
      # Use a fixed period that includes all our test data
      subject { described_class.new(user: user, period: "all") }

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
      before { travel_to Date.new(2023, 2, 1) }
      after { travel_back }

      # Use a period that only includes January and February
      subject { described_class.new(user: user, period: "past_year") }

      it "only includes balances within the specified period" do
        results = subject.accounts.to_a

        savings = results.find { |a| a.name == "Savings Account" }
        investment = results.find { |a| a.name == "Investment Account" }

        # The final balances should reflect February, not March
        expect(savings.final_balance.to_f).to be_within(0.01).of(62.0)     # 6200 cents as of Feb 1
        expect(investment.final_balance.to_f).to be_within(0.01).of(105.0) # 10500 cents as of Feb 1
      end
    end
  end

  describe "#totals" do
    subject { described_class.new(user: user, period: "all") }

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

  describe "#new_accounts" do
    subject { described_class.new(user: user, period: "all") }

    context "when there are new and empty accounts" do
      let!(:new_account) { user.accounts.create!(name: "New Account", currency: "MXN", created_at: 30.days.ago) }

      it "returns accounts that are new and empty" do
        # Since the account has no balances and was created recently, it should be new_and_empty
        new_accounts = subject.new_accounts
        expect(new_accounts).to include(new_account)
      end
    end

    context "when there are no new accounts" do
      # Both existing accounts have balances, so they shouldn't be hidden
      it "returns an empty collection when all accounts have balances" do
        new_accounts = subject.new_accounts
        expect(new_accounts).to be_empty
      end
    end
  end

  describe "#disabled_accounts" do
    subject { described_class.new(user: user, period: "all") }

    context "when there are disabled accounts" do
      let!(:disabled_account) { user.accounts.create!(name: "Disabled Account", currency: "MXN", active: false, created_at: 2.years.ago) }

      it "returns accounts that are not new and empty" do
        # Account is old and should not be considered new_and_empty
        disabled_accounts = subject.disabled_accounts
        expect(disabled_accounts).to include(disabled_account)
      end
    end

    context "when there are no disabled accounts" do
      it "returns an empty collection" do
        disabled_accounts = subject.disabled_accounts
        expect(disabled_accounts).to be_empty
      end
    end
  end

  describe "hidden accounts behavior" do
    subject { described_class.new(user: user, period: "all") }

    let!(:new_account) { user.accounts.create!(name: "New Account", currency: "MXN", created_at: 30.days.ago) }
    let!(:disabled_account) { user.accounts.create!(name: "Disabled Account", currency: "MXN", active: false, created_at: 2.years.ago) }

    it "excludes hidden accounts from main accounts list" do
      main_accounts = subject.accounts.to_a
      account_names = main_accounts.map(&:name)

      expect(account_names).not_to include("New Account")
      expect(account_names).not_to include("Disabled Account")
      expect(account_names).to contain_exactly("Investment Account", "Savings Account")
    end

    it "properly categorizes hidden accounts" do
      new_accounts = subject.new_accounts
      disabled_accounts = subject.disabled_accounts

      expect(new_accounts).to include(new_account)
      expect(disabled_accounts).to include(disabled_account)
      expect(new_accounts).not_to include(disabled_account)
      expect(disabled_accounts).not_to include(new_account)
    end
  end
end
