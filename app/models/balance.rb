class Balance < ApplicationRecord
  belongs_to :account

  monetize :amount_cents
  monetize :transfers_cents
  monetize :diff_cents, allow_nil: true

  before_save :calculate_diffs
  after_save :maybe_convert_to_mxn

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

  # Get the exchange rate for this balance
  # @return [Float] The exchange rate to MXN
  def exchange_rate
    CurrencyConverter.exchange_rate_for(self)
  end

  # Get MXN equivalent of this balance
  # @return [Balance] The MXN balance for this record
  def to_mxn
    return self unless foreign_currency?
    CurrencyConverter.to_mxn(self)
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

  def maybe_convert_to_mxn
    return unless currency != "MXN" && account.currency != "MXN"
    to_mxn # Automatically converts to MXN and saves
  end

  def calculate_diffs
    @prev = nil
    if prev
      self.diff_cents = amount_cents - transfers_cents - prev.amount_cents
      self.diff_days = date - prev.date
    else
      self.diff_days = 1
      self.diff_cents = 0
    end
  end
end
