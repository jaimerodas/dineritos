class User < ApplicationRecord
  has_many :sessions
  has_many :accounts
  has_many :balance_dates
end
