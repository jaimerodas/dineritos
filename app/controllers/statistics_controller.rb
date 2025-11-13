class StatisticsController < ApplicationController
  before_action :auth

  def show
    @report = AccountReport.new(
      account: account,
      user: current_user,
      currency: params[:currency].blank? ? "default" : params[:currency],
      period: params[:period].blank? ? "past_year" : params[:period]
    )
  end

  private

  def account
    @account ||= Account.find(params[:account_id])
  end
end
