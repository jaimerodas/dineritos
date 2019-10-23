class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  enum account_type: %i[default bitso yotepresto briq]
  encrypts :settings, type: :json

  validates :name, presence: true

  def updateable?
    %w[yotepresto briq].include? account_type
  end
end
