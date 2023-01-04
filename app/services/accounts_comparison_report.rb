class AccountsComparisonReport
  def initialize(user:, period: "past_year")
    @user = user
    @user_accounts = user.accounts
    @period = calculate_period_from(period)
  end

  attr_reader :period

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

  def totals
    accounts.reduce({balance: BigDecimal("0"), earnings: BigDecimal("0"), transfers: BigDecimal("0")}) do |result, account|
      {
        balance: result[:balance] + BigDecimal(account.final_balance),
        earnings: result[:earnings] + BigDecimal(account.total_earnings),
        transfers: result[:transfers] + BigDecimal(account.total_transferred)
      }
    end
  end

  private

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

  def calculate_period_from(year)
    return 1.year.ago..Date.current if year == "past_year"
    return earliest_date..Date.current if year == "all"
    return 1.month.ago..Date.current if year == "past_month"
    return 1.week.ago..Date.current if year == "past_week"
    year = year.to_i if year.instance_of?(String)
    Date.new(year)...Date.new(year + 1)
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

  def earliest_date
    @earliest_date ||= @user.balances.earliest_date
  end
end
