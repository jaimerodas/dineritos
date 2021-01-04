class MovementsController < ApplicationController
  before_action :auth

  def index
    @report = AccountBalances.new(
      user: current_user,
      account: account,
      month: params[:month] || Date.current.strftime("%Y-%m")
    )
  end

  private

  def account
    @account ||= Account.find(params[:account_id])
  end
end
