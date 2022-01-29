class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    create_session_for(user) if user
    redirect_to root_path
  end

  def destroy
    log_out
  end

  private

  def create_session_for(user)
    user.sessions.available.each do |s|
      next unless s.token_matches? params[:token]
      s.refresh && s.remember
      log_in(user)
      cookies.permanent.signed[:session_id] = s.id
      cookies.permanent[:remember_token] = s.remember_token
      break
    end
  end
end
