class Charts::BalancesController < ApplicationController
  before_action :auth

  def show
    render json: HistoricInvestmentData.for(
      current_user,
      period: params[:period].blank? ? "past_year" : params[:period]
    ).data
  end
end
