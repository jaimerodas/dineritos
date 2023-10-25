class UpdatesController < ApplicationController
  before_action :auth
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  before_action :ensure_updateability

  def show
    account.latest_balance
    ServicesMailer.daily_update(current_user).deliver_now if user_wants_to_be_notified?
  ensure
    redirect_to account_path(params[:account_id])
  end

  def not_found
    render :not_found
  end

  private

  def account
    @account ||= current_user.accounts.updateable.find(params[:account_id])
  end

  def ensure_updateability
    redirect_to account_path(params[:account_id]) unless account.can_be_updated?
  end

  def user_wants_to_be_notified?
    current_user.settings && current_user.settings["send_email_after_update"]
  end
end
