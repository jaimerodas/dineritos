class InvestmentsController < ApplicationController
  before_action :auth

  def show
    @report = HistoricInvestmentData.for(current_user)
    @summary = InvestmentSummary.for(user: current_user, period: Date.current.year)
  end
end
