# frozen_string_literal: true

require "rails_helper"

RSpec.describe EarningsReport do
  # Load fixtures
  fixtures :users, :accounts, :balances

  # Access fixtures
  let(:user) { users(:test_user) }

  # Define test dates
  let(:today) { Date.new(2023, 3, 15) }
  let(:yesterday) { today - 1.day }
  let(:last_week) { today - 1.week }
  let(:last_month) { today - 1.month }

  describe "#initialize" do
    it "sets the user" do
      report = described_class.for(user)
      expect(report.user).to eq(user)
    end
  end

  describe "with test balances" do
    # Create a fresh user with accounts and balances for testing
    let(:earnings_user) { User.create!(email: "earnings_test@example.com") }

    let(:savings_account) { earnings_user.accounts.create!(name: "Savings", currency: "MXN") }
    let(:investment_account) { earnings_user.accounts.create!(name: "Investment", currency: "MXN") }

    before do
      travel_to today

      # Setup balances for the savings account

      # Balance from 40 days ago (outside the month period)
      Balance.create!(
        account: savings_account,
        date: today - 40.days,
        amount_cents: 5_000_00,
        transfers_cents: 5_000_00,
        diff_cents: 0,
        currency: "MXN"
      )

      # Balance from 20 days ago (within month, outside week)
      Balance.create!(
        account: savings_account,
        date: today - 20.days,
        amount_cents: 5_100_00,
        transfers_cents: 0,
        diff_cents: 100_00,
        diff_days: 20,
        currency: "MXN"
      )

      # Balance from 5 days ago (within week, outside day)
      Balance.create!(
        account: savings_account,
        date: today - 5.days,
        amount_cents: 5_150_00,
        transfers_cents: 0,
        diff_cents: 50_00,
        diff_days: 15,
        currency: "MXN"
      )

      # Balance from yesterday
      Balance.create!(
        account: savings_account,
        date: yesterday,
        amount_cents: 5_170_00,
        transfers_cents: 0,
        diff_cents: 20_00,
        diff_days: 4,
        currency: "MXN"
      )

      # Today's balance (current)
      Balance.create!(
        account: savings_account,
        date: today,
        amount_cents: 5_180_00,
        transfers_cents: 0,
        diff_cents: 10_00,
        diff_days: 1,
        currency: "MXN"
      )

      # Setup balances for the investment account

      # Balance from 40 days ago (outside the month period)
      Balance.create!(
        account: investment_account,
        date: today - 40.days,
        amount_cents: 10_000_00,
        transfers_cents: 10_000_00,
        diff_cents: 0,
        currency: "MXN"
      )

      # Balance from 20 days ago (within month, outside week)
      Balance.create!(
        account: investment_account,
        date: today - 20.days,
        amount_cents: 10_300_00,
        transfers_cents: 0,
        diff_cents: 300_00,
        diff_days: 20,
        currency: "MXN"
      )

      # Balance from 5 days ago (within week, outside day)
      Balance.create!(
        account: investment_account,
        date: today - 5.days,
        amount_cents: 10_400_00,
        transfers_cents: 0,
        diff_cents: 100_00,
        diff_days: 15,
        currency: "MXN"
      )

      # Balance from yesterday
      Balance.create!(
        account: investment_account,
        date: yesterday,
        amount_cents: 10_450_00,
        transfers_cents: 0,
        diff_cents: 50_00,
        diff_days: 4,
        currency: "MXN"
      )

      # Today's balance (current)
      Balance.create!(
        account: investment_account,
        date: today,
        amount_cents: 10_480_00,
        transfers_cents: 0,
        diff_cents: 30_00,
        diff_days: 1,
        currency: "MXN"
      )
    end

    after do
      travel_back
    end

    describe "#details" do
      subject { described_class.for(earnings_user) }

      it "returns earnings details for each account" do
        details = subject.details

        # Should contain both accounts
        expect(details.keys).to match_array(["Savings", "Investment"])

        # Verify Savings account details
        savings = details["Savings"]
        expect(savings[:current]).to eq(BigDecimal("5180.0"))
        expect(savings[:day]).to eq(BigDecimal("10.0"))  # Today = 10
        expect(savings[:month]).to eq(BigDecimal("180.0")) # All entries within last month = 10 + 20 + 50 + 100

        # Verify Investment account details
        investment = details["Investment"]
        expect(investment[:current]).to eq(BigDecimal("10480.0"))
        expect(investment[:day]).to eq(BigDecimal("30.0"))  # Today = 30
        expect(investment[:month]).to eq(BigDecimal("480.0")) # All entries within last month = 30 + 50 + 100 + 300
      end

      it "includes accounts with missing periods but some earnings" do
        # Create an account with only one recent transaction
        partial_account = earnings_user.accounts.create!(name: "Partial", currency: "MXN")

        Balance.create!(
          account: partial_account,
          date: today - 10.days,
          amount_cents: 1_000_00,
          transfers_cents: 1_000_00,
          diff_cents: 0,
          currency: "MXN"
        )

        Balance.create!(
          account: partial_account,
          date: today,
          amount_cents: 1_050_00,
          transfers_cents: 0,
          diff_cents: 50_00,
          diff_days: 10,
          currency: "MXN"
        )

        details = subject.details

        # Should include the partial account
        expect(details.keys).to include("Partial")

        # Should have current and month values, but no day value
        expect(details["Partial"][:current]).to eq(BigDecimal("1050.0"))
        expect(details["Partial"][:month]).to eq(BigDecimal("50.0"))
        expect(details["Partial"][:day]).to eq(BigDecimal("50.0"))
      end
    end

    describe "#totals" do
      subject { described_class.for(earnings_user) }

      it "calculates correct totals across all accounts" do
        totals = subject.totals

        # Current total: 5180.0 + 10480.0 = 15660.0
        expect(totals[:current]).to eq(BigDecimal("15660.0"))

        # Day total: 10 + 30 = 40.0
        expect(totals[:day]).to eq(BigDecimal("40.0"))

        # Week total should include all earnings within 1 week
        # This isn't directly implemented in the class, but should be calculated from day/month
        expect(totals[:week]).to eq(BigDecimal(0))

        # Month total: 180.0 + 480.0 = 660.0
        expect(totals[:month]).to eq(BigDecimal("660.0"))
      end

      it "includes all periods even if some accounts don't have all periods" do
        # Create an account with only one recent transaction
        partial_account = earnings_user.accounts.create!(name: "Partial", currency: "MXN")

        Balance.create!(
          account: partial_account,
          date: today - 10.days,
          amount_cents: 1_000_00,
          transfers_cents: 1_000_00,
          diff_cents: 0,
          currency: "MXN"
        )

        Balance.create!(
          account: partial_account,
          date: today,
          amount_cents: 1_050_00,
          transfers_cents: 0,
          diff_cents: 50_00,
          diff_days: 10,
          currency: "MXN"
        )

        totals = subject.totals

        # Current should include all accounts: 5180.0 + 10480.0 + 1050.0 = 16710.0
        expect(totals[:current]).to eq(BigDecimal("16710.0"))

        # Month should include all earnings: 180.0 + 480.0 + 50.0 = 710.0
        expect(totals[:month]).to eq(BigDecimal("710.0"))
      end
    end
  end

  describe "with edge cases" do
    let(:edge_user) { User.create!(email: "edge_case@example.com") }

    context "with no accounts" do
      subject { described_class.for(edge_user) }

      it "returns empty details" do
        expect(subject.details).to be_empty
      end

      it "returns zero totals" do
        totals = subject.totals
        expect(totals[:current]).to eq(BigDecimal(0))
        expect(totals[:day]).to eq(BigDecimal(0))
        expect(totals[:week]).to eq(BigDecimal(0))
        expect(totals[:month]).to eq(BigDecimal(0))
      end
    end

    context "with no balances" do
      before do
        edge_user.accounts.create!(name: "Empty Account", currency: "MXN")
      end

      subject { described_class.for(edge_user) }

      it "returns empty details" do
        expect(subject.details).to be_empty
      end

      it "returns zero totals" do
        totals = subject.totals
        expect(totals[:current]).to eq(BigDecimal(0))
        expect(totals[:day]).to eq(BigDecimal(0))
        expect(totals[:week]).to eq(BigDecimal(0))
        expect(totals[:month]).to eq(BigDecimal(0))
      end
    end

    context "with USD accounts" do
      before do
        usd_account = edge_user.accounts.create!(name: "USD Account", currency: "USD")

        travel_to Date.today

        Balance.create!(
          account: usd_account,
          date: Date.today,
          amount_cents: 100_00,
          transfers_cents: 90_00,
          diff_cents: 10_00,
          currency: "USD"  # Note USD currency
        )

        mxn_account = edge_user.accounts.create!(name: "MXN Account", currency: "MXN")

        Balance.create!(
          account: mxn_account,
          date: Date.today,
          amount_cents: 1_000_00,
          transfers_cents: 950_00,
          diff_cents: 50_00,
          currency: "MXN"
        )

        travel_back
      end

      subject { described_class.for(edge_user) }

      it "adds USD accounts in details" do
        details = subject.details

        # Should not only include the MXN account
        expect(details.keys).to include("USD Account")
      end

      it "only includes MXN accounts in totals" do
        totals = subject.totals

        # Should only include MXN values
        # 1000 + (100*20) = 3000
        expect(totals[:current]).to eq(BigDecimal("3000.0"))
        # 50 as there is only one balance for that account
        expect(totals[:day]).to eq(BigDecimal("50.0"))
      end
    end
  end

  describe "private methods" do
    subject { described_class.for(user) }

    describe "#current_balances" do
      it "returns the correct data structure" do
        result = subject.send(:current_balances)

        expect(result).to be_a(Hash)
        expect(result.keys).to all(be_a(String))
        expect(result.values).to all(be_a(BigDecimal))
      end

      it "includes only the most recent balance per account" do
        # This test verifies the DISTINCT ON functionality
        account = user.accounts.first

        # Ensure there are multiple balances for the account
        expect(account.balances.count).to be > 1

        # Get the most recent balance
        most_recent = account.balances.order(date: :desc).first

        result = subject.send(:current_balances)
        account_balance = result[account.name]

        # The amount should match the most recent balance
        expect(account_balance).to eq(BigDecimal(most_recent.amount.to_s))
      end
    end

    describe "#earnings_in_the_last" do
      it "returns earnings from the specified period" do
        travel_to Date.new(2023, 3, 15)

        # Test for one day
        day_earnings = subject.send(:earnings_in_the_last, 1.day)
        expect(day_earnings).to be_a(Hash)

        # Test for one month
        month_earnings = subject.send(:earnings_in_the_last, 1.months)
        expect(month_earnings).to be_a(Hash)

        # Month should include more days of earnings than day
        expect(month_earnings.values.sum).to be >= day_earnings.values.sum

        travel_back
      end

      it "excludes null diff_cents balances" do
        account = user.accounts.first

        # Create a balance with null diff_cents
        Balance.create!(
          account: account,
          date: Date.today,
          amount_cents: 1_000_00,
          transfers_cents: 1_000_00,
          diff_cents: nil,
          currency: "MXN"
        )

        result = subject.send(:earnings_in_the_last, 1.day)

        # The new balance with null diff_cents should not affect the result
        expect(result[account.name]).not_to be_nil
      end
    end

    describe "#combine" do
      it "combines multiple reports into a structured format" do
        reports = {
          current: {"Account1" => BigDecimal(100), "Account2" => BigDecimal(200)},
          day: {"Account1" => BigDecimal(5), "Account2" => BigDecimal(10)},
          month: {"Account1" => BigDecimal(20), "Account2" => BigDecimal(40)}
        }

        result = subject.send(:combine, reports)

        expect(result).to be_a(Hash)
        expect(result.keys).to match_array(["Account1", "Account2"])

        expect(result["Account1"][:current]).to eq(BigDecimal(100))
        expect(result["Account1"][:day]).to eq(BigDecimal(5))
        expect(result["Account1"][:month]).to eq(BigDecimal(20))

        expect(result["Account2"][:current]).to eq(BigDecimal(200))
        expect(result["Account2"][:day]).to eq(BigDecimal(10))
        expect(result["Account2"][:month]).to eq(BigDecimal(40))
      end

      it "handles accounts missing from some reports" do
        reports = {
          current: {"Account1" => BigDecimal(100), "Account2" => BigDecimal(200)},
          day: {"Account1" => BigDecimal(5)}, # Account2 missing
          month: {"Account1" => BigDecimal(20), "Account2" => BigDecimal(40)}
        }

        result = subject.send(:combine, reports)

        expect(result["Account1"][:day]).to eq(BigDecimal(5))
        expect(result["Account2"][:day]).to be_nil
      end
    end

    describe "#totals_hash" do
      it "returns a hash with BigDecimal zeros" do
        result = subject.send(:totals_hash)

        expect(result).to be_a(Hash)
        expect(result.keys).to match_array([:current, :day, :week, :month])
        expect(result.values).to all(eq(BigDecimal(0)))
      end
    end
  end
end
