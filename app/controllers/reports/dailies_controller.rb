class Reports::DailiesController < ApplicationController
  before_action :auth
  before_action :validate_date

  def show
    @report = DailyReport.for(current_user, params[:d])
  end

  private

  def date_validates?
    params[:d] &&
    params[:d] =~ /\A\d{4}\-\d{2}\-\d{2}\z/ &&
    Date.parse(params[:d]) <= Date.current &&
    Date.parse(params[:d]) > current_user.balances.earliest_date
  end

  def validate_date
    redirect_to reports_dailies_path(d: Date.current) unless date_validates?
  end
end
