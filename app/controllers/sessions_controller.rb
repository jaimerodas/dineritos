class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    create_session_for(user) if user
    redirect_to root_path
  end

  def destroy
    logout
  end

  private

  def create_session_for(user)
    user.sessions.where("valid_until > ?", Time.current).where(claimed_at: nil).each do |s|
      next unless BCrypt::Password.new(s.token) == params[:token]
      session[:auth] = Rails.application.credentials[:auth_secret]
      s.update_attribute(:claimed_at, Time.current)
      break
    end
  end
end
