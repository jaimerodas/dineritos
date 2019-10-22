class AccountsController < ApplicationController
  before_action :auth

  def index
    @accounts = current_user.accounts.order(active: :desc, id: :asc)
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
    @report = BalanceReport.new(account: params[:id], user: current_user, page: params[:page])
  end

  private

  def account_params
    params.require(:account).permit(:name, :currency, :account_type, settings: {})
  end
end
