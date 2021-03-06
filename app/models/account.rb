class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  PLATFORMS = %i[no_platform bitso yo_te_presto briq afluenta la_tasa cetes_directo red_girasol]

  enum platform: PLATFORMS
  enum account_type: %i[checking investment]

  encrypts :settings, type: :json
  scope :updateable, -> { where.not(platform: :no_platform) }
  scope :foreign_currency, -> { where(platform: :no_platform).where.not(currency: "MXN") }

  validates :name, presence: true

  def updateable?
    platform != "no_platform"
  end

  def can_be_updated?
    !last_amount.date || last_amount.date < Date.current
  end

  def can_be_updated_automatically?
    can_be_updated? && updateable?
  end

  def update_service
    platform.camelize
      .then { |name| "Updaters::#{name}".constantize }
  end

  def last_amount
    balances.where(currency: currency).order(date: :desc).limit(1).first || Balance.new
  end

  def latest_balance(force: false)
    return last_amount.amount if last_amount.date == Date.current && !force
    balance = balances.find_or_initialize_by(date: Date.current, currency: currency)
    balance.update(amount: update_service.current_balance_for(self))
    BigDecimal(balance.amount.to_d)
  end
end
