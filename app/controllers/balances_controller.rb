class BalancesController < ApplicationController
  before_action :auth
  before_action :balance, only: %i[show edit]

  def index
    dates = BalanceDate.select(:id).order(date: :desc).map(&:id)
    puts dates
    @report = BalanceReport.new(dates)
  end

  def show
  end

  def new
    latest_balance = BalanceDate.includes(balances: :account).order(date: :desc).limit(1).first
    @balance = BalanceDate.new(date: Date.today)

    if latest_balance
      latest_balance.balances.each do |b|
        next if b.amount == 0
        @balance.balances.build(account: b.account, amount: b.original_amount || b.amount)
      end
      Account.where(active: true)
        .where.not(id: latest_balance.balances.map(&:account_id))
        .each do |account|
        @balance.balances.build(account: account, amount: 0)
      end
    else
      Account.where(active: true).each do |account|
        @balance.balances.build(account: account, amount: 0)
      end
    end
  end

  def create
    create_or_modify_balance
  end

  def edit
  end

  def update
    create_or_modify_balance
  end

  def delete
  end

  private

  def balance_date_params
    {
      date: params.require(:balance_date)
        .permit(:date).to_h
        .map { |k, v| k.ends_with?("1i)") ? v : v.rjust(2, "0") }
        .join("-"),
    }
  end

  def balances_params
    params.require(:balance_date)
      .permit(balances_attributes: [:account_id, :amount])[:balances_attributes]
  end

  def create_or_modify_balance
    @balance_date = BalanceDate.find_or_create_by(balance_date_params)
    @balance_date.balances.destroy_all
    @balance_date.total&.destroy

    balances_params.each do |key, balance_params|
      @balance_date.balances.create(balance_params)
    end

    CalculateTotal.from(@balance_date)
    DeactivateAccounts.from(@balance_date)

    redirect_to balance_path(@balance_date.date)
  end

  def balance
    @balance = BalanceDate.includes(:total, balances: :account).find_by(date: params[:date])
  end
end
