class BalancesController < ApplicationController
  before_action :auth
  before_action :balance, only: %i[edit]

  def index
    @report = BalanceReport.new(user: current_user, page: params[:page])
  end

  def show
    @report = AccountDetailReport.new(current_user.balance_dates.id_range_from(params[:date]))
  end

  def new
    latest_balance = current_user.balance_dates.includes(balances: :account).where("accounts.account_type": 0)
      .order(date: :desc).limit(1).first
    @balance = current_user.balance_dates.new(date: Date.today)

    if latest_balance
      latest_balance.balances.each do |b|
        next if b.amount == 0
        @balance.balances.build(account: b.account, amount: b.original_amount || b.amount)
      end
      current_user.accounts.default.where(active: true)
        .where.not(id: latest_balance.balances.map(&:account_id))
        .each do |account|
        @balance.balances.build(account: account, amount: 0)
      end
    else
      current_user.accounts.default.where(active: true).each do |account|
        @balance.balances.build(account: account, amount: 0)
      end
    end

    @bitsos = current_user.accounts.bitso.select(:name)
  end

  def create
    CreateBalance.from(user: current_user, params: balances_params)
    redirect_to root_path
  end

  def delete
  end

  private

  def balances_params
    params.require(:balance_date)
      .permit(balances_attributes: [:account_id, :amount])[:balances_attributes]
  end

  def balance
    @balance = current_user.balance_dates.includes(:total, balances: :account).find_by(date: params[:date])
  end
end
