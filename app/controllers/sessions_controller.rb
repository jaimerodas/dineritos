class SessionsController < ApplicationController
  def create
    Session.where("valid_until > ?", Time.current).where(claimed_at: nil).each do |client_session|
      next unless BCrypt::Password.new(client_session.token) == params[:token]
      session[:auth] = Rails.application.credentials[:auth_secret]
      client_session.update_attribute(:claimed_at, Time.current)
      redirect_to root_path
    end
  end
end
