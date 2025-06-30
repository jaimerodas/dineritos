class StatisticsController < ApplicationController
  before_action :auth

  def show
    @report = AccountReport.new(
      account: account,
      user: current_user,
      currency: params[:currency].blank? ? "default" : params[:currency]
    )
  end

  private

  def account
    @account ||= Account.find(params[:account_id])
  end
end
