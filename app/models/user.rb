class User < ApplicationRecord
  has_many :sessions
  has_many :accounts
  has_many :balances, through: :accounts

  before_create { self.email = email.downcase }

  def accounts_missing_todays_balance
    account_ids = balances
      .select("DISTINCT ON (balances.account_id) balances.account_id, balances.date, balances.validated")
      .order("balances.account_id ASC").order("balances.date DESC")
      .reject { |balance| balance.date == Date.current && balance.validated }
      .map(&:account_id)

    accounts.where(id: account_ids)
  end
end
