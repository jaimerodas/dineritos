class Total < ApplicationRecord
  belongs_to :balance_date

  monetize :amount_cents
end
