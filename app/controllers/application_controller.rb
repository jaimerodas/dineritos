class ApplicationController < ActionController::Base
  private

  def auth
    return if session[:auth] == Rails.application.credentials[:auth_secret]
    session[:auth] = nil
    redirect_to login_path
  end
end
