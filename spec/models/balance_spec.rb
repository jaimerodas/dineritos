require "rails_helper"

RSpec.describe Balance, type: :model do
  let(:user) { User.create!(email: "test_balances@example.com") }
  let(:account) { Account.create!(name: "A", currency: "MXN", user: user) }
  let!(:b1) { Balance.create!(account: account, date: Date.yesterday, amount_cents: 1000, transfers_cents: 0, currency: "MXN", validated: true) }
  let!(:b2) { Balance.create!(account: account, date: Date.today, amount_cents: 1500, transfers_cents: 200, currency: "MXN", validated: false) }

  it "belongs to account" do
    assoc = described_class.reflect_on_association(:account)
    expect(assoc.macro).to eq(:belongs_to)
  end

  describe "diff calculation" do
    it "computes diff_cents and diff_days on save" do
      expect(b2.diff_cents).to eq(1500 - 200 - 1000)
      expect(b2.diff_days).to eq((Date.today - Date.yesterday).to_i)
    end

    it "doesn't calculate diffs when there is no previous balance" do
      new_account = Account.create!(name: "B", currency: "MXN", user: user)
      new_balance = Balance.create!(account: new_account, date: Date.today, amount_cents: 2000, transfers_cents: 100, currency: "MXN")

      expect(new_balance.diff_cents).to be_nil
      expect(new_balance.diff_days).to be_nil
    end
  end

  describe ".earliest_date and .latest_date" do
    it "returns correct earliest and latest dates" do
      expect(user.balances.earliest_date).to eq(Date.yesterday)
      expect(user.balances.latest_date).to eq(Date.today)
    end

    it "returns current date when no balances exist" do
      Balance.delete_all

      expect(Balance.earliest_date).to eq(Date.current)
      expect(Balance.latest_date).to eq(Date.current)
    end
  end

  describe "#prev, #prev_validated, and #next" do
    it "returns the previous balance" do
      expect(b2.prev).to eq(b1)
    end

    it "returns the previous validated balance" do
      unvalidated_balance = Balance.create!(
        account: account,
        date: Date.yesterday - 1.day,
        amount_cents: 500,
        transfers_cents: 0,
        currency: "MXN",
        validated: false
      )

      expect(b1.prev).to eq(unvalidated_balance)
      expect(b1.prev_validated).to be_nil
    end

    it "returns the next balance" do
      expect(b1.next).to eq(b2)
      expect(b2.next).to be_nil
    end
  end

  describe "#foreign_currency?" do
    it "returns false for MXN currency" do
      expect(b1.foreign_currency?).to be false
    end

    it "returns true for non-MXN currency" do
      usd_balance = Balance.create!(
        account: account,
        date: Date.today,
        amount_cents: 100,
        transfers_cents: 0,
        currency: "USD"
      )

      expect(usd_balance.foreign_currency?).to be true
    end
  end

  describe "#exchange_rate" do
    before do
      allow(CurrencyExchange).to receive(:get_rate_for).and_return(19.5) # 19.5 MXN per USD
    end

    it "returns 1.0 for MXN currency" do
      expect(b1.exchange_rate).to eq(1.0)
    end

    it "returns currency rate for non-MXN currency" do
      usd_balance = Balance.create!(
        account: account,
        date: Date.today,
        amount_cents: 100,
        transfers_cents: 0,
        currency: "USD"
      )

      expect(usd_balance.exchange_rate).to eq(19.5)
    end
  end

  describe "currency conversion" do
    let(:usd_account) { Account.create!(name: "USD Account", currency: "USD", user: user) }

    before do
      # Create a stubbed currency rate object
      fake_rate = instance_double("CurrencyRate", rate_subcents: 19_500_000)
      allow(CurrencyRate).to receive(:find_or_create_by).and_return(fake_rate)
    end

    it "creates MXN balance when saving foreign currency balance" do
      # Ensure no MXN balance exists first
      expect(Balance.where(account: usd_account, currency: "MXN", date: Date.today).count).to eq(0)

      # Create USD balance
      Balance.create!(
        account: usd_account,
        date: Date.today,
        amount_cents: 1000, # 10 USD
        transfers_cents: 200, # 2 USD
        currency: "USD",
        validated: true
      )

      # Check that MXN balance was created
      mxn_balance = Balance.find_by(account: usd_account, currency: "MXN", date: Date.today)
      expect(mxn_balance).to be_present
      expect(mxn_balance.amount_cents).to eq(19_500) # 10 USD * 19.5 = 195 MXN
      expect(mxn_balance.transfers_cents).to eq(3_900) # 2 USD * 19.5 = 39 MXN
      expect(mxn_balance.validated).to eq(true)
    end

    it "doesn't create MXN balance when account currency is MXN" do
      # Track initial MXN balance count
      initial_count = Balance.where(currency: "MXN").count

      # Create new MXN balance
      Balance.create!(
        account: account,
        date: Date.today + 1.day,
        amount_cents: 2000,
        transfers_cents: 0,
        currency: "MXN"
      )

      # Count should only increase by 1
      expect(Balance.where(currency: "MXN").count).to eq(initial_count + 1)
    end
  end
end
