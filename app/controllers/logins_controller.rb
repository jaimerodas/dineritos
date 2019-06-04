class LoginsController < ApplicationController
  before_action :reverse_auth

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

  def reverse_auth
    redirect_to root_path if logged_in?
  end
end
