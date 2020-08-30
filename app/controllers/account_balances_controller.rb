class AccountBalancesController < ApplicationController
  before_action :auth
  before_action :balance_missing?, only: %i[new create]
  before_action :account_balance, only: %i[edit update]

  def new
    @balance = Balance.new(date: Date.current, account: account, amount: account.last_amount.amount)
  end

  def create
    @balance = current_user.balances.build(
      account_balance_params.merge({
        date: Date.current,
        account: account,
        currency: account.currency
      })
    )

    if @balance.save
      ServicesMailer.daily_update(current_user).deliver_now
      redirect_to account_path(@balance.account)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if UpdateBalance.run(balance: @balance, params: account_balance_params)
      redirect_to account_path(@balance.account)
    else
      render :edit
    end
  end

  private

  def account
    @account ||= current_user.accounts.find(params[:account_id])
  end

  def account_balance
    @balance = current_user.balances.find(params[:id])
  end

  def account_balance_params
    params.require(:balance).permit(:amount, :transfers)
  end

  def balance_missing?
    redirect_to account_path(account) unless account.balances.where(date: Date.current).empty?
  end
end
