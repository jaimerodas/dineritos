class User < ApplicationRecord
  has_many :sessions
  has_many :accounts
  has_many :balances, through: :accounts
  has_many :passkeys

  before_create { self.email = email.downcase }
  after_initialize { self.uid ||= WebAuthn.generate_user_id }

  def accounts_missing_todays_balance
    account_ids = balances
      .select(:account_id)
      .where(date: Balance.latest_date, validated: false, amount_cents: 1..)

    accounts.where(id: account_ids).order(name: :asc)
  end

  def inactive_accounts_missing_todays_balance
    account_ids = balances
      .select(:account_id)
      .where(date: Balance.latest_date, validated: false, amount_cents: ..0)
      .order(name: :asc)

    accounts.where(id: account_ids).order(name: :asc)
  end
end
