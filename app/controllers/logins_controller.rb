class LoginsController < ApplicationController
  layout "login"

  def show
  end

  def create
    if valid_email?
      token = SecureRandom.urlsafe_base64

      Session.create(
        token: BCrypt::Password.create(token),
        valid_until: 15.minutes.from_now
      )

      SessionsMailer.login(token: token).deliver_now
    end
  end

  private

  def valid_email?
    params.require(:session).permit(:email)[:email] == Rails.application.credentials[:email]
  end
end
