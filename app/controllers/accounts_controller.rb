class AccountsController < ApplicationController
  before_action :auth

  def index
    @accounts = Account.order(active: :desc, id: :asc)
  end

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    if @account.save
      redirect_to accounts_path
    else
      render :new
    end
  end

  private

  def account_params
    params.require(:account).permit(:name, :currency)
  end
end
