class Reports::StatementsController < ApplicationController
  before_action :auth

  def show
    period = params[:period].presence || Date.current.year.to_s
    @statement = Reports::PortfolioStatement.new(current_user, period)
  end
end
