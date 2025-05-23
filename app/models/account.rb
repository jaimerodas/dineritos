class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  enum :platform, {
    no_platform: 0,
    bitso: 1,
    afluenta: 2,
    apify: 4
  }

  has_encrypted :settings, type: :json
  scope :updateable, -> { where.not(platform: :no_platform) }
  scope :foreign_currency, -> { where(platform: :no_platform).where.not(currency: "MXN") }
  scope :active, -> { where(active: true) }
  scope :by_status, -> {
    joins(:balances)
      .select("accounts.*", "balances.amount_cents > 0 as valid")
      .where("balances.date": Balance.latest_date, "balances.currency": "MXN")
      .order(valid: :desc, name: :asc)
  }

  validates :name, presence: true

  def updateable?
    platform != "no_platform"
  end

  def can_be_updated?
    !last_amount.validated
  end

  def can_be_reset?
    updateable? && last_amount.validated && last_amount.amount_cents.zero?
  end

  def reset!
    return unless can_be_reset?
    today = last_amount
    yesterday = last_amount.prev
    today.amount_cents = yesterday.amount_cents
    today.save
  end

  def can_be_updated_automatically?
    can_be_updated? && updateable?
  end

  def update_service
    platform.camelize
      .then { |name| "Updaters::#{name}".constantize }
  end

  def last_amount(use: currency)
    balances.where(currency: use).order(date: :desc).limit(1).first || Balance.new
  end

  def latest_balance(force: false)
    return last_amount.amount if last_amount.date == Date.current && last_amount.validated && !force
    balance = balances.find_or_initialize_by(date: Date.current, currency: currency)
    balance.update(amount: update_service.current_balance_for(self), validated: true)
    BigDecimal(balance.amount.to_d)
  end
end
