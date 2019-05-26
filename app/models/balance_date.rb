class BalanceDate < ApplicationRecord
    has_many :balances
    has_one :total
end
