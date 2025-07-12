class AccountsComparisonReport
  include Reports::Helpers::PeriodHelper

  def initialize(user:, period: "past_year")
    @user = user
    @user_accounts = user.accounts
    @period = calculate_period(period, earliest_date: earliest_date)
  end

  attr_reader :period, :user

  def accounts
    @accounts ||= Account
      .select(:id, :name)
      .select(decimalized("initial_balance"))
      .select(decimalized("SUM(transfers_cents) - initial_transfer", "total_transferred"))
      .select(decimalized("SUM(diff_cents) - initial_diff", "total_earnings"))
      .select(decimalized("initial_balance - initial_transfer - initial_diff + SUM(transfers_cents) + SUM(diff_cents)", "final_balance"))
      .from(all_balances_from_period)
      .group(:id, :name, :initial_balance, :initial_transfer, :initial_diff)
      .order(name: :asc)
  end

  def new_accounts
    @new_accounts ||= hidden_accounts.select(&:new_and_empty?)
  end

  def disabled_accounts
    @disabled_accounts ||= hidden_accounts.reject(&:new_and_empty?)
  end

  def totals
    accounts.reduce({balance: BigDecimal(0), earnings: BigDecimal(0), transfers: BigDecimal(0)}) do |result, account|
      {
        balance: result[:balance] + BigDecimal(account.final_balance || 0),
        earnings: result[:earnings] + BigDecimal(account.total_earnings || 0),
        transfers: result[:transfers] + BigDecimal(account.total_transferred)
      }
    end
  end

  private

  def hidden_accounts
    @hidden_accounts ||= begin
      visible_account_ids = accounts.pluck(:id)
      @user_accounts.where.not(id: visible_account_ids).order(created_at: :asc)
    end
  end

  def all_balances_from_period
    @user_accounts.joins(:balances)
      .select(
        :id, :name,
        first_value("amount_cents", "initial_balance"),
        first_value("transfers_cents", "initial_transfer"),
        first_value("diff_cents", "initial_diff"),
        "balances.transfers_cents", "balances.diff_cents", "balances.date"
      )
      .where("balances.currency": "MXN", "balances.date": period)
  end

  def first_value(column, key)
    "
    COALESCE(
      FIRST_VALUE(balances.#{column})
      OVER (PARTITION BY accounts.id ORDER BY balances.date ASC)
    , 0) AS #{key}
    "
  end

  def decimalized(column, key = false)
    key ||= column
    "(#{column}) / 100.0 AS #{key}"
  end
end
