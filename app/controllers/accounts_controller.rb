class AccountsController < ApplicationController
  before_action :auth
  DEFAULT_PERIOD = "past_year"

  def index
    report = AccountsComparisonReport.new(
      user: current_user,
      period: params[:period].blank? ? DEFAULT_PERIOD : params[:period]
    )
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
    @report = AccountReport.new(
      account: account,
      user: current_user,
      currency: params[:currency].blank? ? "default" : params[:currency]
    )
  end

  def reset
    @account = current_user.accounts.find(params[:account_id])
    if @account.reset!
      ServicesMailer.new_daily_update(current_user).deliver_now if user_wants_to_be_notified?
    end
    redirect_to account_movements_path(@account)
  end

  private

  def user_wants_to_be_notified?
    current_user.settings && current_user.settings["send_email_after_update"]
  end

  def account_params
    params.require(:account).permit(:name, :currency, :platform, settings: {})
  end

  def account
    @account ||= Account.find(params[:id])
  end
end
