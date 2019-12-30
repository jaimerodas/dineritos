class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  UPDATEABLE = %i[yotepresto briq afluenta latasa cetesdirecto]
  NOT_UPDATEABLE = %i[default bitso]

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
      .zip(%w[YoTePresto Briq Afluenta LaTasa CetesDirecto]).to_h
      .fetch(account_type.to_sym)
      .then { |name| "Scrapers::#{name}".constantize }
  end

  def last_amount
    balances.order(date: :desc).limit(1).first
  end

  def latest_balance(force: false)
    return last_amount if last_amount.date == Date.today && !force
    balances.create(date: Date.today, amount: update_service.current_balance_for(self))
  end
end
