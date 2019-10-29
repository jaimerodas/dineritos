class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  UPDATEABLE = %i[yotepresto briq afluenta latasa cetesdirecto]
  NOT_UPDATEABLE = %i[default bitso]

  enum account_type: (NOT_UPDATEABLE + UPDATEABLE)
  encrypts :settings, type: :json
  scope :updateable, -> { where(account_type: UPDATEABLE) }
  monetize :last_balance_cents

  validates :name, presence: true

  def updateable?
    UPDATEABLE.include? account_type.to_sym
  end

  def update_service
    UPDATEABLE.zip([
      YtpService, BriqService, AfluentaService, LaTasaService, CetesDirectoService
    ]).to_h.fetch(account_type.to_sym)
  end

  def latest_balance(force: false)
    return last_balance if last_balance_updated_at&.>(12.hours.ago) && !force
    last_balance = update_service.current_balance_for(self)
    update(last_balance: last_balance, last_balance_updated_at: Time.current)
    last_balance
  end
end
