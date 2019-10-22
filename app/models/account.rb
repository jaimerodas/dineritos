class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  enum account_type: %i[default bitso yotepresto]
  encrypts :settings, type: :json

  validates :name, presence: true
end
