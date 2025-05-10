require "rails_helper"

RSpec.describe User, type: :model do
  describe "email normalization" do
    it "downcases email before create" do
      user = User.create!(email: "Foo@ExamPle.Com")
      expect(user.email).to eq("foo@example.com")
    end
  end

  describe "uid generation" do
    it "assigns uid on initialize if blank" do
      user = User.new(email: "x@x.com")
      expect(user.uid).to be_present
    end

    it "does not overwrite existing uid" do
      existing_uid = WebAuthn.generate_user_id
      user = User.new(email: "x@x.com", uid: existing_uid)
      expect(user.uid).to eq(existing_uid)
    end
  end

  describe "associations" do
    it "has many passkeys" do
      assoc = described_class.reflect_on_association(:passkeys)
      expect(assoc.macro).to eq(:has_many)
    end

    it "has many sessions" do
      assoc = described_class.reflect_on_association(:sessions)
      expect(assoc.macro).to eq(:has_many)
    end

    it "has many accounts" do
      assoc = described_class.reflect_on_association(:accounts)
      expect(assoc.macro).to eq(:has_many)
    end

    it "has many balances through accounts" do
      assoc = described_class.reflect_on_association(:balances)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:through]).to eq(:accounts)
    end
  end

  describe "account management" do
    let(:user) { User.create!(email: "test@example.com") }

    it "can create accounts" do
      account = user.accounts.create!(name: "Test Account", currency: "MXN")
      expect(user.accounts.count).to eq(1)
      expect(account.user).to eq(user)
    end

    it "raises error if accounts exist when user is destroyed" do
      user.accounts.create!(name: "Test Account", currency: "MXN")
      expect { user.destroy }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "accounts missing balances" do
    let(:user) { User.create!(email: "test@example.com") }
    let(:account1) { user.accounts.create!(name: "Account 1", currency: "MXN") }
    let(:account2) { user.accounts.create!(name: "Account 2", currency: "MXN") }
    let(:account3) { user.accounts.create!(name: "Account 3", currency: "MXN") }
    let(:today) { Date.current }

    before do
      # Setup: Allow Balance.latest_date to return today
      allow(Balance).to receive(:latest_date).and_return(today)

      # Create balances for today with various states
      account1.balances.create!(date: today, amount_cents: 1500, transfers_cents: 0, currency: "MXN", validated: false)
      account2.balances.create!(date: today, amount_cents: 0, transfers_cents: 0, currency: "MXN", validated: false)
      account3.balances.create!(date: today, amount_cents: 2000, transfers_cents: 0, currency: "MXN", validated: true)
    end

    describe "#accounts_missing_todays_balance" do
      it "returns accounts with unvalidated positive balances for today" do
        missing_accounts = user.accounts_missing_todays_balance

        expect(missing_accounts).to include(account1)
        expect(missing_accounts).not_to include(account2) # amount is 0
        expect(missing_accounts).not_to include(account3) # already validated
      end

      it "returns accounts in alphabetical order" do
        # Create additional accounts with unvalidated balances
        account_z = user.accounts.create!(name: "Z Account", currency: "MXN")
        account_a = user.accounts.create!(name: "A Account", currency: "MXN")

        account_z.balances.create!(date: today, amount_cents: 1000, transfers_cents: 0, currency: "MXN", validated: false)
        account_a.balances.create!(date: today, amount_cents: 1000, transfers_cents: 0, currency: "MXN", validated: false)

        missing_accounts = user.accounts_missing_todays_balance

        expect(missing_accounts.first).to eq(account_a)
        expect(missing_accounts.last).to eq(account_z)
      end
    end

    describe "#inactive_accounts_missing_todays_balance" do
      it "returns accounts with unvalidated zero or negative balances for today" do
        missing_accounts = user.inactive_accounts_missing_todays_balance

        expect(missing_accounts).to include(account2) # amount is 0
        expect(missing_accounts).not_to include(account1) # amount is positive
        expect(missing_accounts).not_to include(account3) # already validated
      end

      it "includes accounts with negative balances" do
        account_neg = user.accounts.create!(name: "Negative", currency: "MXN")
        account_neg.balances.create!(date: today, amount_cents: -500, transfers_cents: 0, currency: "MXN", validated: false)

        missing_accounts = user.inactive_accounts_missing_todays_balance

        expect(missing_accounts).to include(account_neg)
        expect(missing_accounts).to include(account2) # amount is 0
      end
    end
  end
end
