class Investments::SummariesController < ApplicationController
  before_action :auth

  def show
    @summary = InvestmentSummary.for(
      user: current_user,
      period: params[:period].blank? ? "past_year" : params[:period]
    )

    render "shared/_investments_summary", layout: false
  end
end
