class DashboardsController < ApplicationController
  before_action :auth

  def show
    @balance = BalanceDate.includes(:total, balances: :account).order(date: :desc).limit(1).first
  end
end
