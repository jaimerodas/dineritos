class Total < ApplicationRecord
  belongs_to :balance_date

  self.per_page = 10

  monetize :amount_cents
end
