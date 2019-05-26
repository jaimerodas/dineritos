class Balance < ApplicationRecord
  belongs_to :account
  belongs_to :balance_date

  monetize :amount_cents
  monetize :original_amount_cents, allow_nil: true

  before_save :convert_currency, if: proc { account.currency != "MXN" }

  private

  def convert_currency
    rate = balance_date.currency_rates.find_or_create_by(currency: account.currency).rate_subcents
    self.original_amount_cents = amount_cents
    self.amount_cents = (original_amount_cents * rate / 1000000.0).to_i
  end
end
