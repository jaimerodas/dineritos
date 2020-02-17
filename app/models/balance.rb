class Balance < ApplicationRecord
  belongs_to :account
  # belongs_to :user

  monetize :amount_cents
  monetize :transfers_cents
  monetize :original_amount_cents, allow_nil: true
  monetize :diff_cents, allow_nil: true

  before_validation :convert_currency, if: proc { account.currency != "MXN" && account.no_platform? }
  before_save :calculate_diffs

  def prev
    self.class.where(account: account).where("date < ?", date).order(date: :desc).limit(1).first
  end

  def next
    self.class.where(account: account).where("date > ?", date).order(date: :asc).limit(1).first
  end

  private

  def convert_currency
    rate = CurrencyRate.find_or_create_by(date: date, currency: account.currency).rate_subcents
    self.amount_cents = (original_amount_cents * rate / 1000000.0).to_i
  end

  def calculate_diffs
    return unless prev
    self.diff_cents = amount_cents - transfers_cents - prev.amount_cents
    self.diff_days = date - prev.date
  end
end
