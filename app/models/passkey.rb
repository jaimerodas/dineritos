class Passkey < ApplicationRecord
  # Each passkey belongs to a user account
  belongs_to :user
  validates :external_id, :public_key, :nickname, :sign_count, presence: true
  validates :external_id, uniqueness: true
end
