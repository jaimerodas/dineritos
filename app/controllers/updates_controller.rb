class UpdatesController < ApplicationController
  before_action :auth
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def show
    @balance = get_balance_for(account)
  end

  def not_found
    render :not_found
  end

  private

  def account
    @account ||= current_user.accounts.where(account_type: :yotepresto).find(params[:account_id])
  end

  def get_balance_for(a)
    Rails.cache.fetch(
      "accounts/#{a.id}/balance",
      expires_in: 12.hours,
      force: flush_cache?
    ) do
      YtpService.current_balance_for(a)
    end
  end

  def flush_cache?
    params[:force] == "true"
  end
end
