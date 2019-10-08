class DashboardsController < ApplicationController
  before_action :auth

  def show
    @report = AccountDetailReport.latest_for(current_user)
  end
end
