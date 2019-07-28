class DashboardsController < ApplicationController
  before_action :auth

  def show
    @report = AccountDetailReport.latest
  end
end
