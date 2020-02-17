class BalancesController < ApplicationController
  before_action :auth

  def index
    @report = BalanceReport.new(user: current_user, page: params[:page])
  end

  def show
    @report = AllAccountsReport.new(current_user.totals.dates_from(params[:date]))
  end

  def new
    @data = NewTotal.for(current_user)
  end

  def create
    CreateTotal.from(user: current_user, params: balances_params)
    redirect_to root_path
  end

  private

  def balances_params
    params.require(:accounts).permit(account: {})
  end
end
