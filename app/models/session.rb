class Session < ApplicationRecord
  belongs_to :user

  before_create :set_attributes

  attr_accessor :token, :remember_token

  scope :available, -> { where("expires_at > ?", Time.current).where(remember_digest: nil) }

  def token_matches?(t)
    BCrypt::Password.new(token_digest).is_password?(t)
  end

  def authenticated?(t)
    BCrypt::Password.new(remember_digest).is_password?(t)
  end

  def remember
    raise unless remember_digest.nil?
    self.remember_token = SecureRandom.urlsafe_base64
    update_attribute(:remember_digest, BCrypt::Password.create(remember_token))
  end

  private

  def set_attributes
    self.expires_at = 15.minutes.from_now
    self.token = SecureRandom.urlsafe_base64
    self.token_digest = BCrypt::Password.create(token)
  end
end
