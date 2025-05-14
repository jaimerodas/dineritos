class AccountBalancesController < ApplicationController
  before_action :auth
  before_action :set_account, only: %i[new create]
  before_action :set_balance, only: %i[edit update]

  def new
    @balance = Balance.new(
      date: Date.current,
      account: @account,
      amount: @account.last_amount.amount,
      currency: @account.currency
    )
  end

  def create
    @balance = current_user.balances.find_or_initialize_by(
      date: Date.current, account: @account, currency: @account.currency
    )

    if UpdateBalance.run(balance: @balance, params: account_balance_params)
      redirect_to account_movements_path(@balance.account)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if UpdateBalance.run(balance: @balance, params: account_balance_params)
      redirect_to account_movements_path(@balance.account, month: @balance.date.strftime("%Y-%m"))
    else
      render :edit
    end
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id])
  end

  def set_balance
    @balance = current_user.balances.find(params[:id])
  end

  def account_balance_params
    params.require(:balance).permit(:amount, :transfers)
  end
end
