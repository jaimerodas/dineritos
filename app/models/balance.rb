class Balance < ApplicationRecord
  belongs_to :account

  monetize :amount_cents
  monetize :transfers_cents
  monetize :diff_cents, allow_nil: true

  before_save :calculate_diffs
  after_save :convert_currency, if: proc { currency != "MXN" && account.currency != "MXN" }

  def prev
    @prev ||= prev_set.limit(1).first
  end

  def prev_validated
    @prev_validated ||= prev_set.where(validated: true).limit(1).first
  end

  def next
    self.class
      .where(account: account, currency: currency)
      .where("date > ?", date)
      .order(date: :asc).limit(1).first
  end

  def foreign_currency?
    @foreign_currency ||= (currency != "MXN")
  end

  def exchange_rate
    @exchange_rate ||= if foreign_currency?
      CurrencyRate.find_or_create_by(date: date, currency: currency).rate_subcents / 1000000.0
    else
      1.0
    end
  end

  def self.earliest_date
    select(:date).order(date: :asc).limit(1).first&.date || Date.current
  end

  def self.latest_date
    select(:date).order(date: :desc).limit(1).first&.date || Date.current
  end

  private

  def prev_set
    self.class
      .where(account: account, currency: currency)
      .where("date < ?", date)
      .order(date: :desc)
  end

  def convert_currency
    Balance.find_or_initialize_by(
      account: account,
      date: date,
      currency: "MXN"
    ).update(
      validated: validated,
      amount_cents: (amount_cents * exchange_rate).to_i,
      transfers_cents: (transfers_cents * exchange_rate).to_i
    )
  end

  def calculate_diffs
    @prev = nil
    return unless prev
    self.diff_cents = amount_cents - transfers_cents - prev.amount_cents
    self.diff_days = date - prev.date
  end
end
