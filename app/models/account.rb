class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  UPDATEABLE = %i[yotepresto briq afluenta latasa cetesdirecto]
  NOT_UPDATEABLE = %i[default bitso]

  enum account_type: (NOT_UPDATEABLE + UPDATEABLE)
  encrypts :settings, type: :json
  scope :updateable, -> { where(account_type: UPDATEABLE) }

  validates :name, presence: true

  def updateable?
    UPDATEABLE.include? account_type.to_sym
  end
end
