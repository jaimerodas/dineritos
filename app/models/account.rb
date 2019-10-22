class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  enum account_type: %i[default bitso]
  encrypts :settings, type: :json, migrating: true

  validates :name, presence: true
end
