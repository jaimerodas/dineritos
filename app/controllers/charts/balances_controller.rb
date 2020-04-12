class Charts::BalancesController < ApplicationController
  before_action :auth

  def show
    render json: HistoricInvestmentData.for(current_user).data
  end
end
