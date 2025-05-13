require "rails_helper"

RSpec.describe UpdateAllAccounts do
  # Simple test classes to avoid excessive mocking
  class TestUser
    attr_reader :email, :settings, :active_accounts, :updateable_accounts

    def initialize(email: "test@example.com", settings: nil)
      @email = email
      @settings = settings
      @active_accounts = []
      @updateable_accounts = []
    end

    def accounts
      self
    end

    def active
      @active_accounts
    end

    def updateable
      @updateable_accounts
    end
  end

  class TestAccount
    attr_reader :name, :currency, :last_amount_value, :can_reset
    attr_accessor :latest_balance_called, :balance_updated

    def initialize(name:, currency: "MXN", last_amount_value: 1000, can_reset: false)
      @name = name
      @currency = currency
      @last_amount_value = last_amount_value
      @can_reset = can_reset
      @latest_balance_called = false
      @balance_updated = false
    end

    def can_be_reset?
      @can_reset
    end

    def last_amount
      OpenStruct.new(amount_cents: @last_amount_value)
    end

    def latest_balance(force: false)
      @latest_balance_called = true
      @last_amount_value
    end

    def balances
      self
    end

    def find_or_initialize_by(date:, currency:)
      self
    end

    def update(amount_cents:)
      @balance_updated = true
      true
    end
  end

  class TestMailer
    attr_reader :emails_sent

    def initialize
      @emails_sent = []
    end

    def new_daily_update(user, errors: [], actions: [])
      @emails_sent << {user: user, errors: errors, actions: actions}
      self
    end

    def deliver_now
      true
    end
  end

  # Test data setup
  let(:mailer) { TestMailer.new }

  let(:user_with_email) do
    user = TestUser.new(settings: {"daily_email" => true})

    # Add test accounts to user
    user.active_accounts << active_account
    user.updateable_accounts << reset_account
    user.updateable_accounts << normal_account

    user
  end

  let(:user_without_email) do
    user = TestUser.new(settings: {})

    # Add test accounts to user
    user.active_accounts << active_account2
    user.updateable_accounts << updateable_account

    user
  end

  let(:active_account) { TestAccount.new(name: "Active Account") }
  let(:active_account2) { TestAccount.new(name: "Active Account 2") }
  let(:updateable_account) { TestAccount.new(name: "Updateable Account") }
  let(:reset_account) { TestAccount.new(name: "Reset Account", can_reset: true) }
  let(:normal_account) { TestAccount.new(name: "Normal Account") }

  let(:users) { [user_with_email, user_without_email] }

  # Skip actual sleeping in tests
  before do
    allow_any_instance_of(UpdateAllAccounts).to receive(:sleep)
  end

  describe ".run" do
    it "returns a summary of processed accounts" do
      result = UpdateAllAccounts.run(users: users, mailer_service: mailer)

      expect(result).to include(
        processed: 2,
        errors: 0,
        actions: 1  # One reset account
      )
    end
  end

  describe "#run" do
    it "updates balances for active accounts" do
      UpdateAllAccounts.run(users: users, mailer_service: mailer)

      expect(active_account.balance_updated).to be true
      expect(active_account2.balance_updated).to be true
    end

    it "forces update for updateable accounts" do
      UpdateAllAccounts.run(users: users, mailer_service: mailer)

      expect(updateable_account.latest_balance_called).to be true
      expect(reset_account.latest_balance_called).to be true
      expect(normal_account.latest_balance_called).to be true
    end

    it "sends emails only to users with daily_email setting" do
      UpdateAllAccounts.run(users: users, mailer_service: mailer)

      expect(mailer.emails_sent.length).to eq(1)
      expect(mailer.emails_sent.first[:user]).to eq(user_with_email)
    end

    it "includes reset actions in the email" do
      UpdateAllAccounts.run(users: users, mailer_service: mailer)

      email = mailer.emails_sent.first
      expect(email[:actions]).to include(account: reset_account, action: :reset)
    end
  end

  context "when account update fails" do
    let(:error_account) do
      account = TestAccount.new(name: "Error Account")

      # Make this account raise an error when latest_balance is called
      allow(account).to receive(:latest_balance).and_raise("API Error")

      account
    end

    let(:user_with_error) do
      user = TestUser.new
      user.updateable_accounts << error_account
      user
    end

    it "captures errors during account updates" do
      service = UpdateAllAccounts.new(
        users: [user_with_error],
        mailer_service: mailer,
        max_retries: 1,
        retry_delay: 0
      )

      service.run

      expect(service.errors).to include(
        hash_including(
          account: "Error Account",
          error: "RuntimeError",
          message: "API Error"
        )
      )
    end

    it "retries failed account updates according to max_retries" do
      expect(error_account).to receive(:latest_balance).exactly(2).times

      UpdateAllAccounts.new(
        users: [user_with_error],
        mailer_service: mailer,
        max_retries: 1,
        retry_delay: 0
      ).run
    end
  end
end
