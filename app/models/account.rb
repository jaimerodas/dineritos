class Account < ApplicationRecord
  belongs_to :user
  has_many :balances

  enum account_type: %i[default bitso]

  validates :name, presence: true
end
