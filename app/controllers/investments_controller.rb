class InvestmentsController < ApplicationController
  before_action :auth

  def show
    @report = HistoricInvestmentData.for(current_user)
  end
end
