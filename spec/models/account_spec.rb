require "rails_helper"

RSpec.describe Account, type: :model do
  fixtures :users, :accounts

  let(:user) { users(:test_user) }

  subject { described_class.new(name: "Acct1", currency: "MXN", user: user) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is invalid without a name" do
    subject.name = nil
    expect(subject).not_to be_valid
  end

  it "belongs to user" do
    assoc = described_class.reflect_on_association(:user)
    expect(assoc.macro).to eq(:belongs_to)
  end

  it "has many balances" do
    assoc = described_class.reflect_on_association(:balances)
    expect(assoc.macro).to eq(:has_many)
  end

  describe "scopes" do
    let!(:active_account) { described_class.create!(name: "Active", currency: "MXN", user: user, active: true) }
    let!(:inactive_account) { described_class.create!(name: "Inactive", currency: "MXN", user: user, active: false) }
    let!(:platform_account) { described_class.create!(name: "Platform", currency: "MXN", user: user, platform: "bitso") }
    let!(:no_platform_account) { described_class.create!(name: "No Platform", currency: "MXN", user: user, platform: "no_platform") }
    let!(:foreign_account) { described_class.create!(name: "Foreign", currency: "USD", user: user, platform: "no_platform") }

    it "returns only active accounts with active scope" do
      expect(described_class.active).to include(active_account)
      expect(described_class.active).not_to include(inactive_account)
    end

    it "returns only updateable accounts with updateable scope" do
      expect(described_class.updateable).to include(platform_account)
      expect(described_class.updateable).not_to include(no_platform_account)
    end

    it "returns only foreign currency accounts with foreign_currency scope" do
      expect(described_class.foreign_currency).to include(foreign_account)
      expect(described_class.foreign_currency).not_to include(no_platform_account)
    end
  end

  describe "#last_amount" do
    let(:account) { described_class.create!(name: "Test Account", currency: "MXN", user: user) }

    it "returns a Balance instance when none exist" do
      ba = account.last_amount
      expect(ba).to be_a(Balance)
    end

    it "returns the latest balance for the specified currency" do
      yesterday = Date.yesterday
      today = Date.current

      account.balances.create!(date: yesterday, amount_cents: 1000, currency: "MXN")
      today_balance = account.balances.create!(date: today, amount_cents: 2000, currency: "MXN")

      expect(account.last_amount).to eq(today_balance)
    end

    it "allows specifying a different currency" do
      account.balances.create!(date: Date.current, amount_cents: 1000, currency: "MXN")
      usd_balance = account.balances.create!(date: Date.current, amount_cents: 50, currency: "USD")

      expect(account.last_amount(use: "USD")).to eq(usd_balance)
    end
  end

  describe "#updateable?" do
    it "returns false for no_platform accounts" do
      account = described_class.new(platform: "no_platform")
      expect(account.updateable?).to be_falsey
    end

    it "returns true for platform accounts" do
      account = described_class.new(platform: "bitso")
      expect(account.updateable?).to be_truthy
    end
  end

  describe "#can_be_updated?" do
    let(:account) { described_class.create!(name: "Test Account", currency: "MXN", user: user) }

    it "returns true when last amount is not validated" do
      account.balances.create!(date: Date.current, amount_cents: 1000, currency: "MXN", validated: false)
      expect(account.can_be_updated?).to be_truthy
    end

    it "returns false when last amount is validated" do
      account.balances.create!(date: Date.current, amount_cents: 1000, currency: "MXN", validated: true)
      expect(account.can_be_updated?).to be_falsey
    end
  end

  describe "#can_be_reset?" do
    let(:account) { described_class.create!(name: "Test Account", currency: "MXN", user: user, platform: "bitso") }

    it "returns true for updateable account with validated zero balance" do
      account.balances.create!(date: Date.current, amount_cents: 0, currency: "MXN", validated: true)
      expect(account.can_be_reset?).to be_truthy
    end

    it "returns false for non-updateable account" do
      no_platform = described_class.create!(name: "No Platform", currency: "MXN", user: user, platform: "no_platform")
      no_platform.balances.create!(date: Date.current, amount_cents: 0, currency: "MXN", validated: true)
      expect(no_platform.can_be_reset?).to be_falsey
    end

    it "returns false when balance is not validated" do
      account.balances.create!(date: Date.current, amount_cents: 0, currency: "MXN", validated: false)
      expect(account.can_be_reset?).to be_falsey
    end

    it "returns false when balance is not zero" do
      account.balances.create!(date: Date.current, amount_cents: 100, currency: "MXN", validated: true)
      expect(account.can_be_reset?).to be_falsey
    end
  end

  describe "#can_be_updated_automatically?" do
    it "returns true when account can be updated and is updateable" do
      account = described_class.create!(name: "Test", currency: "MXN", user: user, platform: "bitso")
      account.balances.create!(date: Date.current, amount_cents: 1000, currency: "MXN", validated: false)

      expect(account.can_be_updated_automatically?).to be_truthy
    end

    it "returns false when account can't be updated" do
      account = described_class.create!(name: "Test", currency: "MXN", user: user, platform: "bitso")
      account.balances.create!(date: Date.current, amount_cents: 1000, currency: "MXN", validated: true)

      expect(account.can_be_updated_automatically?).to be_falsey
    end

    it "returns false when account isn't updateable" do
      account = described_class.create!(name: "Test", currency: "MXN", user: user, platform: "no_platform")
      account.balances.create!(date: Date.current, amount_cents: 1000, currency: "MXN", validated: false)

      expect(account.can_be_updated_automatically?).to be_falsey
    end
  end

  describe "#update_service" do
    it "returns the appropriate updater class" do
      account = described_class.new(platform: "bitso")
      expect(account.update_service.to_s).to eq("Updaters::Bitso")
    end
  end

  describe "#reset!" do
    let(:account) { described_class.create!(name: "Test Account", currency: "MXN", user: user, platform: "bitso") }

    it "resets today's balance to yesterday's value when conditions are met" do
      yesterday = Date.yesterday
      today = Date.current

      account.balances.create!(date: yesterday, amount_cents: 1000, currency: "MXN", validated: true)
      today_balance = account.balances.create!(date: today, amount_cents: 0, currency: "MXN", validated: true)

      account.reset!
      today_balance.reload

      expect(today_balance.amount_cents).to eq(1000)
    end

    it "does nothing when account cannot be reset" do
      today = Date.current
      today_balance = account.balances.create!(date: today, amount_cents: 1000, currency: "MXN", validated: true)

      account.reset!
      today_balance.reload

      expect(today_balance.amount_cents).to eq(1000)
    end
  end
end
