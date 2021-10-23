class User < ApplicationRecord
  has_many :sessions
  has_many :accounts
  has_many :balances, through: :accounts

  before_create { self.email = email.downcase }
end
