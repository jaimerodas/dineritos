class DashboardsController < ApplicationController
  before_action :auth

  def show
    @report = AllAccountsReport.latest_for(current_user)
  end
end
