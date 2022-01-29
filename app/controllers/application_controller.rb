class ApplicationController < ActionController::Base
  private

  def auth
    return if logged_in?
    log_out
  end

  def log_in(user)
    session[:user_id] = user.id
  end

  def log_out
    session.delete(:user_id)
    Session.find_by(id: cookies.signed[:session_id])&.destroy
    cookies.delete(:session_id)
    cookies.delete(:remember_token)
    @current_user = nil
    redirect_to login_path
  end

  def logged_in?
    !current_user.nil?
  end

  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find(user_id)
    elsif (session_id = cookies.signed[:session_id])
      session = Session.find_by(id: session_id)
      if session&.authenticated?(cookies[:remember_token]) && !session&.expired?
        session.refresh!
        log_in(session.user)
        @current_user = session.user
      end
    end
  end
end
