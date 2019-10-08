class LoginsController < ApplicationController
  before_action :reverse_auth

  layout "login"

  def show
  end

  def create
    if valid_email?
      session = @user.sessions.create
      SessionsMailer.login(user: @user, token: session.token).deliver_now
    end
  end

  private

  def valid_email?
    @user = User.find_by(email: params_email)
  end

  def params_email
    params.require(:session).permit(:email)[:email]&.downcase
  end

  def reverse_auth
    redirect_to root_path if logged_in?
  end
end
