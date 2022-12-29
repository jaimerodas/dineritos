class AccountsController < ApplicationController
  before_action :auth

  def index
    report = AccountsComparisonReport.new(user: current_user)
    @accounts = report.accounts
    @totals = report.totals
  end

  def new
    @account = current_user.accounts.build
  end

  def create
    @account = current_user.accounts.build(account_params)

    if @account.save
      redirect_to accounts_path
    else
      render :new
    end
  end

  def edit
    @account = current_user.accounts.find(params[:id])
  end

  def update
    @account = current_user.accounts.find(params[:id])

    if @account.update(account_params)
      redirect_to account_path(@account)
    else
      render :edit
    end
  end

  def show
    @report = AccountReport.new(account: account, user: current_user)
  end

  private

  def account_params
    params.require(:account).permit(:name, :currency, :platform, settings: {})
  end

  def account
    @account ||= Account.find(params[:id])
  end
end
