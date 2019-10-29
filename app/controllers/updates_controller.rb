class UpdatesController < ApplicationController
  before_action :auth
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def show
    @balance = account.latest_balance(force: flush_cache?)
  end

  def not_found
    render :not_found
  end

  private

  def account
    @account ||= current_user.accounts.updateable.find(params[:account_id])
  end

  def flush_cache?
    params[:force] == "true"
  end
end
