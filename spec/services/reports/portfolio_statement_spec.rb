require "rails_helper"

RSpec.describe Reports::PortfolioStatement do
  fixtures :users, :accounts, :balances

  let(:user) { users(:test_user) }

  describe "#initialize" do
    before { travel_to Date.new(2023, 3, 15) }
    after { travel_back }

    it "sets user and period" do
      statement = described_class.new(user, "past_month")
      expect(statement.user).to eq(user)
      expect(statement.period).to be_a(Range)
      expect(statement.period_string).to eq("past_month")
    end
  end

  describe "#account_lines" do
    subject { described_class.new(user, "all") }

    it "returns one entry per active account" do
      results = subject.account_lines.to_a
      expect(results.size).to eq(2)
      expect(results.map(&:name)).to contain_exactly("Savings Account", "Investment Account")
    end

    it "calculates financial metrics for savings account" do
      results = subject.account_lines.to_a
      savings = results.find { |l| l.name == "Savings Account" }

      # Starting balance: first balance = 5000 cents = $50.00
      expect(savings.starting_balance.to_f).to be_within(0.01).of(50.0)
      # Deposits: 5000 (jan1) + 1000 (feb1) = 6000, minus initial_transfer 5000 = 1000 cents = $10.00
      expect(savings.deposits.to_f).to be_within(0.01).of(10.0)
      # Withdrawals: none
      expect(savings.withdrawals.to_f).to be_within(0.01).of(0.0)
      # Earnings: 0 + 100 + 100 + 100 = 300, minus initial_diff 0 = 300 cents = $3.00
      expect(savings.earnings.to_f).to be_within(0.01).of(3.0)
      # Final balance: 6300 cents = $63.00
      expect(savings.final_balance.to_f).to be_within(0.01).of(63.0)
    end

    it "calculates financial metrics for investment account" do
      results = subject.account_lines.to_a
      investment = results.find { |l| l.name == "Investment Account" }

      expect(investment.starting_balance.to_f).to be_within(0.01).of(100.0)
      # Deposits: 10000 (jan1) - initial_transfer 10000 = 0
      expect(investment.deposits.to_f).to be_within(0.01).of(0.0)
      # Withdrawals: -2000 (mar1) - 0 (initial_transfer was positive, capped at 0) = -2000 cents = -$20.00
      expect(investment.withdrawals.to_f).to be_within(0.01).of(-20.0)
      # Earnings: 0 + 500 + 300 = 800 - 0 = 800 cents = $8.00
      expect(investment.earnings.to_f).to be_within(0.01).of(8.0)
      expect(investment.final_balance.to_f).to be_within(0.01).of(88.0)
    end

    it "reports each account in its base currency" do
      results = subject.account_lines.to_a
      results.each do |line|
        expect(line.currency).to eq("MXN")
      end
    end

    it "orders by currency then name" do
      results = subject.account_lines.to_a
      expect(results.first.name).to eq("Investment Account")
      expect(results.last.name).to eq("Savings Account")
    end

    it "excludes inactive accounts" do
      user.accounts.create!(name: "Inactive", currency: "MXN", active: false, created_at: 2.years.ago)
      results = subject.account_lines.to_a
      expect(results.map(&:name)).not_to include("Inactive")
    end

    it "excludes accounts with zero balances and no activity" do
      zero_account = user.accounts.create!(name: "Zero Account", currency: "MXN", created_at: 2.years.ago)
      zero_account.balances.create!(date: Date.new(2023, 1, 1), amount_cents: 0, transfers_cents: 0, diff_cents: 0, currency: "MXN")
      zero_account.balances.create!(date: Date.new(2023, 2, 1), amount_cents: 0, transfers_cents: 0, diff_cents: 0, currency: "MXN")
      results = subject.account_lines.to_a
      expect(results.map(&:name)).not_to include("Zero Account")
    end
  end

  describe "#currency_totals" do
    subject { described_class.new(user, "all") }

    it "groups accounts by currency and sums all columns" do
      totals = subject.currency_totals
      expect(totals).to have_key("MXN")

      mxn = totals["MXN"]
      # Savings starting 50 + Investment starting 100 = 150
      expect(mxn[:starting_balance].to_f).to be_within(0.01).of(150.0)
      # Savings deposits 10 + Investment deposits 0 = 10
      expect(mxn[:deposits].to_f).to be_within(0.01).of(10.0)
      # Savings withdrawals 0 + Investment withdrawals -20 = -20
      expect(mxn[:withdrawals].to_f).to be_within(0.01).of(-20.0)
      # Savings earnings 3 + Investment earnings 8 = 11
      expect(mxn[:earnings].to_f).to be_within(0.01).of(11.0)
      # Savings final 63 + Investment final 88 = 151
      expect(mxn[:final_balance].to_f).to be_within(0.01).of(151.0)
    end
  end

  describe "#exchange_rates" do
    subject { described_class.new(user, "all") }

    it "returns empty array when all accounts are MXN" do
      expect(subject.exchange_rates).to eq([])
    end

    context "with a USD account" do
      let!(:usd_account) { user.accounts.create!(name: "USD Fund", currency: "USD") }

      it "returns exchange rate for USD" do
        rates = subject.exchange_rates
        expect(rates.length).to eq(1)
        expect(rates.first[:currency]).to eq("USD")
      end
    end
  end

  describe "#mxn_totals" do
    subject { described_class.new(user, "all") }

    it "returns starting and ending MXN balance" do
      totals = subject.mxn_totals

      # Starting: first balance per account in MXN
      # Savings: 5000 cents ($50) + Investment: 10000 cents ($100) = $150
      expect(totals[:starting_balance].to_f).to be_within(0.01).of(150.0)

      # Final: last balance per account in MXN
      # Savings: 6300 cents ($63) + Investment: 8800 cents ($88) = $151
      expect(totals[:final_balance].to_f).to be_within(0.01).of(151.0)
    end
  end

  describe "#mxn_breakdown" do
    subject { described_class.new(user, "all") }

    it "returns all five breakdown keys" do
      breakdown = subject.mxn_breakdown
      expect(breakdown).to have_key(:transferred_mxn)
      expect(breakdown).to have_key(:earnings_mxn)
      expect(breakdown).to have_key(:transferred_usd_mxn)
      expect(breakdown).to have_key(:earnings_usd_mxn)
      expect(breakdown).to have_key(:fx_gain_loss)
    end

    it "reconciles: starting + breakdown rows = final" do
      totals = subject.mxn_totals
      breakdown = subject.mxn_breakdown

      sum = totals[:starting_balance] +
        breakdown[:transferred_mxn] +
        breakdown[:earnings_mxn] +
        breakdown[:transferred_usd_mxn] +
        breakdown[:earnings_usd_mxn] +
        breakdown[:fx_gain_loss]

      expect(sum.to_f).to be_within(0.01).of(totals[:final_balance].to_f)
    end

    it "has zero USD values when no USD accounts exist" do
      breakdown = subject.mxn_breakdown
      expect(breakdown[:transferred_usd_mxn].to_f).to eq(0.0)
      expect(breakdown[:earnings_usd_mxn].to_f).to eq(0.0)
      expect(breakdown[:fx_gain_loss].to_f).to eq(0.0)
    end

    it "calculates MXN transfers and earnings from currency_totals" do
      breakdown = subject.mxn_breakdown
      # Net transfers: deposits 10 + withdrawals -20 = -10
      expect(breakdown[:transferred_mxn].to_f).to be_within(0.01).of(-10.0)
      # Earnings: 11
      expect(breakdown[:earnings_mxn].to_f).to be_within(0.01).of(11.0)
    end
  end

  describe "#multi_day_period?" do
    it "returns true for multi-day periods" do
      statement = described_class.new(user, "all")
      expect(statement.multi_day_period?).to be true
    end

    it "returns false when period start equals end" do
      # A single-day period where start == end
      statement = described_class.new(user, "all")
      allow(statement).to receive(:period).and_return(Date.current..Date.current)
      expect(statement.multi_day_period?).to be false
    end
  end

  describe "edge cases" do
    it "handles user with no active accounts" do
      empty_user = User.create!(email: "empty@example.com")
      statement = described_class.new(empty_user, "past_month")
      expect(statement.account_lines.to_a).to be_empty
      expect(statement.currency_totals).to eq({})
      expect(statement.exchange_rates).to eq([])
    end
  end
end
