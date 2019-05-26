class BalanceDate < ApplicationRecord
    has_many :balances
    has_many :currency_rates
    has_one :total

    accepts_nested_attributes_for :balances

    def to_param
      date
    end
end
