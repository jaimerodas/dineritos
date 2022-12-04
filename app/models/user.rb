class User < ApplicationRecord
  has_many :sessions
  has_many :accounts
  has_many :balances, through: :accounts

  before_create { self.email = email.downcase }

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
