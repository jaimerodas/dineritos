class Balance < ApplicationRecord
  belongs_to :account
  belongs_to :balance_date
end
