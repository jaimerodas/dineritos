class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  enum account_type: %i[default bitso yotepresto briq afluenta]
  encrypts :settings, type: :json

  validates :name, presence: true

  def updateable?
    %w[yotepresto briq afluenta].include? account_type
  end
end
