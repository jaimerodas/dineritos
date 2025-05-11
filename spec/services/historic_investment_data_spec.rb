# frozen_string_literal: true

require "rails_helper"

RSpec.describe HistoricInvestmentData do
  # Set up test users and accounts
  fixtures :users, :accounts, :balances
  let(:user) { users(:historic_investment_user) }

  # Define time periods for test data
  let(:jan_1) { Date.new(2023, 1, 1) }
  let(:jan_15) { Date.new(2023, 1, 15) }
  let(:feb_1) { Date.new(2023, 2, 1) }
  let(:feb_15) { Date.new(2023, 2, 15) }
  let(:mar_1) { Date.new(2023, 3, 1) }

  # Create test accounts
  let(:investment_account1) { accounts(:hi1_acct) }
  let(:investment_account2) { accounts(:hi2_acct) }
  let(:usd_account) { accounts(:hi3_acct) }

  # Set up test balances with a known history
  before do
    Balance.create!(
      account: investment_account1,
      date: mar_1,
      amount_cents: 12_000,
      currency: "MXN"
    )

    # Investment Account 2
    Balance.create!(
      account: investment_account2,
      date: jan_1,
      amount_cents: 5_000,
      currency: "MXN"
    )

    Balance.create!(
      account: investment_account2,
      date: jan_15,
      amount_cents: 5_200,
      currency: "MXN"
    )

    Balance.create!(
      account: investment_account2,
      date: feb_1,
      amount_cents: 5_400,
      currency: "MXN"
    )

    Balance.create!(
      account: investment_account2,
      date: feb_15,
      amount_cents: 5_600,
      currency: "MXN"
    )

    Balance.create!(
      account: investment_account2,
      date: mar_1,
      amount_cents: 5_800,
      currency: "MXN"
    )

    Balance.create!(
      account: usd_account,
      date: mar_1,
      amount_cents: 1_200,
      currency: "USD"
    )

    travel_to(Date.new(2023, 3, 3))
  end

  after do
    travel_back
  end

  describe ".for" do
    it "returns a properly configured instance" do
      service = described_class.for(user, period: "past_year")

      expect(service).to be_a(HistoricInvestmentData)
      expect(service.user).to eq(user)
      expect(service.period).to be_a(Range)
    end
  end

  describe "#initialize" do
    it "sets user and period attributes" do
      service = described_class.new(user, "past_year")

      expect(service.user).to eq(user)
      expect(service.period).to be_a(Range)
    end

    it "calculates 'past_year' period correctly" do
      service = described_class.new(user, "past_year")

      expect(service.period).to eq(1.year.ago..Date.current)
    end

    it "calculates 'all' period correctly" do
      service = described_class.new(user, "all")

      expect(service.period).to eq(jan_1..Date.current)
    end

    it "calculates year-specific period correctly" do
      service = described_class.new(user, "2023")

      expect(service.period).to eq(Date.new(2023)...Date.new(2024))
    end
  end

  describe "#data" do
    let(:service) { described_class.new(user, "all") }

    it "returns a hash with accounts and balances" do
      data = service.data

      expect(data).to be_a(Hash)
      expect(data).to have_key(:accounts)
      expect(data).to have_key(:balances)
    end

    it "includes account details with name and URL" do
      data = service.data

      expect(data[:accounts]).to be_a(Hash)
      expect(data[:accounts][investment_account1.id]).to be_a(Hash)
      expect(data[:accounts][investment_account1.id][:name]).to eq("Investment Account 1")
      expect(data[:accounts][investment_account1.id][:url]).to eq("/cuentas/#{investment_account1.id}")
    end

    it "formats balances with dates and amounts" do
      data = service.data

      expect(data[:balances]).to be_an(Array)
      expect(data[:balances].length).to be > 0

      # Test the structure of the first balance entry
      first_balance = data[:balances].first
      expect(first_balance).to have_key(:date)
      expect(first_balance).to have_key(investment_account1.id)
      expect(first_balance).to have_key(investment_account2.id)
    end

    it "orders balances by date" do
      data = service.data

      # Extract dates and verify they're in order
      dates = data[:balances].map { |b| Date.parse(b[:date]) }
      expect(dates).to eq(dates.sort)
    end

    it "includes accounts with positive balances only" do
      # Create an account with zero balance
      zero_balance_account = user.accounts.create!(name: "Zero Balance", currency: "MXN")
      Balance.create!(
        account: zero_balance_account,
        date: jan_1,
        amount_cents: 0,
        currency: "MXN"
      )

      data = service.data

      # Zero balance account should not be included
      expect(data[:accounts].keys).not_to include(zero_balance_account.id)
    end
  end

  describe "#latest_date" do
    let(:service) { described_class.new(user, "all") }

    it "returns the date of the most recent balance" do
      expect(service.latest_date).to eq(mar_1)
    end
  end

  describe "#latest_total" do
    let(:service) { described_class.new(user, "all") }

    it "returns the sum of all account balances on the latest date" do
      # Expected sum: Account1 (12,000) + Account2 (5,800) + USD (24,000) = 41,800 cents = 178.0
      expected_total = 418.0

      expect(service.latest_total).to eq(expected_total)
    end
  end

  describe "period filtering" do
    it "filters data for past_year period" do
      service = described_class.new(user, "past_year")
      data = service.data

      # All balances should be from the past year
      dates = data[:balances].map { |b| Date.parse(b[:date]) }
      year_ago = mar_1 - 1.year

      expect(dates.all? { |date| date >= year_ago }).to be true
    end

    it "filters data for specific year period" do
      service = described_class.new(user, "2023")
      data = service.data

      # All balances should be from 2023
      dates = data[:balances].map { |b| Date.parse(b[:date]) }

      expect(dates.all? { |date| date.year == 2023 }).to be true
    end
  end

  describe "data aggregation" do
    let(:service) { described_class.new(user, "all") }

    it "aggregates balances with consistent dates across accounts" do
      data = service.data
      balances = data[:balances]

      # Check that we have the expected number of balance entries
      # We should have 5 dates (Jan 1, Jan 15, Feb 1, Feb 15, Mar 1)
      expect(balances.length).to eq(5)

      # Check that each balance entry includes both accounts
      balances.each do |balance|
        expect(balance).to have_key(investment_account1.id)
        expect(balance).to have_key(investment_account2.id)
      end
    end

    it "carries forward previous balances when a date has no entry" do
      # Create a new account with fewer balance dates
      sparse_account = user.accounts.create!(name: "Sparse Account", currency: "MXN")

      # Only create balances for Jan 1 and Mar 1
      Balance.create!(
        account: sparse_account,
        date: jan_1,
        amount_cents: 1_000,
        currency: "MXN"
      )

      Balance.create!(
        account: sparse_account,
        date: mar_1,
        amount_cents: 2_000,
        currency: "MXN"
      )

      # Re-instantiate service to include the new account
      new_service = described_class.new(user, "all")
      data = new_service.data

      # Get the balance for Jan 15
      jan_15_balance = data[:balances].find { |b| b[:date] == jan_15.to_s }

      # Check that the sparse account balance was carried forward
      expect(jan_15_balance).to have_key(sparse_account.id)
      expect(jan_15_balance[sparse_account.id]).to eq(10.0) # 1,000 cents
    end
  end
end
