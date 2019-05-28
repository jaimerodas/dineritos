class DashboardsController < ApplicationController
  before_action :auth

  def show
    @report = BalanceReport.latest
  end
end
