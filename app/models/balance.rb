class Balance < ApplicationRecord
  belongs_to :account

  monetize :amount_cents
  monetize :original_amount_cents, allow_nil: true

  before_save :convert_currency, if: proc { account.currency != "MXN" && account.default? }

  private

  def convert_currency
    rate = CurrencyRate.find_or_create_by(date: date, currency: account.currency).rate_subcents
    self.original_amount_cents = amount_cents
    self.amount_cents = (original_amount_cents * rate / 1000000.0).to_i
  end
end
