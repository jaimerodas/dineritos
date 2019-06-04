class ApplicationController < ActionController::Base
  private

  def auth
    return if logged_in?
    logout
  end

  def logout
    session.delete(:auth)
    redirect_to login_path
  end

  def logged_in?
    session[:auth] == Rails.application.credentials[:auth_secret]
  end
end
