class InvestmentsController < ApplicationController
  before_action :auth
  DEFAULT_PERIOD = "past_year"

  def show
    @summary = InvestmentSummary.for(
      user: current_user,
      period: params[:period].blank? ? DEFAULT_PERIOD : params[:period]
    )
  end
end
