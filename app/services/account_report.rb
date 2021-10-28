class AccountReport
  def initialize(user:, account:, period: "all")
    raise unless account.user == user
    @account = account
    @period = calculate_period_from(period)
  end

  attr_reader :account, :period

  def account_name
    account.name
  end

  def latest_balance
    account.last_amount
  end

  def earliest_date
    @earliest_date ||= account.balances.earliest_date
  end

  def calculate_period_from(year)
    return 1.year.ago..Date.current if year == "past_year"
    return earliest_date..Date.current if year == "all"
    year = year.to_i if year.instance_of?(String)
    Date.new(year)...Date.new(year + 1)
  end

  def earnings
    @earnings ||= summary.earnings ? summary.earnings / 100.0 : 0.0
  end

  def deposits
    @deposits ||= summary.deposits ? summary.deposits / 100.0 : 0.0
  end

  def withdrawals
    @withdrawals ||= summary.withdrawals ? summary.withdrawals / -100.0 : 0.0
  end

  def irr
    @irr ||= summary.irr
  end

  def monthly_irrs
    available_balances
      .select("DATE(DATE_TRUNC('month', date)) AS month")
      .select(select_irr)
      .group("1").order("1 ASC")
      .map { |balance| "{date: new Date(\"#{balance.month}\"), value: #{balance.irr}}" }
      .join(",")
  end

  def balances_in_period
    available_balances
      .select(:date, :amount_cents)
      .order("1 ASC")
      .map { |balance| "{date: new Date(\"#{balance.date}\"), value: #{balance.amount}}" }
      .join(",")
  end

  private

  def available_balances
    account.balances.where(date: period, currency: account.currency)
  end

  def summary
    available_balances
      .select("SUM(diff_cents) AS earnings")
      .select("SUM(CASE WHEN (transfers_cents > 0) THEN transfers_cents ELSE 0 END ) deposits")
      .select("SUM(CASE WHEN (transfers_cents < 0) THEN transfers_cents ELSE 0 END ) withdrawals")
      .select(select_irr)
      .order("1")
      .first
  end

  def select_irr
    "
      COALESCE((((1 + SUM(
        (diff_cents * 1.0) /
        CASE WHEN (amount_cents - diff_cents - transfers_cents = 0) THEN 1 ELSE (amount_cents - diff_cents - transfers_cents) END
      )) ^
      (365.0 / SUM(diff_days))) - 1), 0)
      AS irr
    "
  end
end
