class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  UPDATEABLE = %i[bitso yotepresto briq afluenta latasa cetesdirecto redgirasol]
  NOT_UPDATEABLE = %i[default]

  enum account_type: (NOT_UPDATEABLE + UPDATEABLE)
  encrypts :settings, type: :json
  scope :updateable, -> { where(account_type: UPDATEABLE) }

  monetize :last_balance_cents, allow_nil: true

  validates :name, presence: true

  def updateable?
    UPDATEABLE.include? account_type.to_sym
  end

  def update_service
    UPDATEABLE
      .zip(%w[Bitso YoTePresto Briq Afluenta LaTasa CetesDirecto RedGirasol]).to_h
      .fetch(account_type.to_sym)
      .then { |name| "Scrapers::#{name}".constantize }
  end

  def last_amount
    balances.order(date: :desc).limit(1).first
  end

  def latest_balance(force: false)
    return last_amount.amount if last_amount.date == Date.today && !force
    balance = balances.find_or_initialize_by(date: Date.today)
    balance.update(amount: update_service.current_balance_for(self))
    BigDecimal(balance.amount.to_d)
  end
end
