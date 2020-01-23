class BalancesController < ApplicationController
  before_action :auth
  before_action :account_balance, only: %i[edit update]

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

  def edit
  end

  def update
    if UpdateBalance.run(balance: @balance, params: account_balance_params)
      redirect_to account_path(params[:account_id])
    else
      render :edit
    end
  end

  def delete
  end

  private

  def balances_params
    params.require(:accounts).permit(account: {})
  end

  def account_balance_params
    params.require(:balance).permit(:amount, :transfers)
  end

  def account_balance
    @balance = current_user.balances.find(params[:id])
  end
end
