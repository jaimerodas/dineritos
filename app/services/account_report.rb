class AccountReport
  include Reports::Helpers::PeriodHelper
  include UserAuthorization
  include CurrencyConversion

  def initialize(user:, account:, period: "all", currency: "default")
    validate_user_account!(user, account)
    @account = account
    @period = calculate_period(period, earliest_date: earliest_date)
    @currency = (currency == "default") ? account.currency : "MXN"
    @period_text = period
  end

  attr_reader :account, :period, :period_text, :currency

  # Basic account information
  def account_name
    account.name
  end

  def latest_balance
    account.last_amount(use: currency)
  end

  def earliest_date
    @earliest_date ||= account.balances.earliest_date
  end

  def earliest_year
    @earliest_year ||= earliest_date.year
  end

  # Financial Metrics
  def earnings
    @earnings ||= cents_to_decimal(summary.earnings)
  end

  def deposits
    @deposits ||= cents_to_decimal(summary.deposits)
  end

  def withdrawals
    @withdrawals ||= (cents_to_decimal(summary.withdrawals) * -1)
  end

  def net_transferred
    deposits - withdrawals
  end

  def irr
    @irr ||= summary.irr
  end

  def final_balance
    @final_balance ||= cents_to_decimal(final_balance_cents)
  end

  def starting_balance
    @starting_balance ||= final_balance - deposits + withdrawals - earnings
  end

  # Chart data
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

  def monthly_pnl
    results = account.balances
      .where(date: period, currency: currency)
      .select(select_pnl)
      .group("month")
      .order("month DESC")

    create_monthly_pnl_array(results, final_balance_cents)
  end

  def total_pnl
    monthly_pnl.each_with_object({
      deposits: BigDecimal(0),
      withdrawals: BigDecimal(0),
      earnings: BigDecimal(0)
    }) do |row, obj|
      obj[:deposits] += row[:deposits]
      obj[:withdrawals] += row[:withdrawals]
      obj[:earnings] += row[:earnings]
    end
  end

  private

  def final_balance_cents
    @final_balance_cents ||= available_balances
      .order(date: :desc)
      .limit(1)
      .first
      .amount_cents
  end

  def available_balances
    account.balances.where(date: period, currency: currency)
  end

  def summary
    @summary ||= available_balances
      .select("SUM(diff_cents) AS earnings")
      .select("SUM(CASE WHEN (transfers_cents > 0) THEN transfers_cents ELSE 0 END ) deposits")
      .select("SUM(CASE WHEN (transfers_cents < 0) THEN transfers_cents ELSE 0 END ) withdrawals")
      .select(select_irr)
      .order(earnings: :desc)
      .first
  end

  def select_irr
    <<~SQL
      COALESCE((((1 + SUM(
        (diff_cents * 1.0) /
        CASE
          WHEN (amount_cents - diff_cents - transfers_cents = 0) THEN 1
          ELSE (amount_cents - diff_cents - transfers_cents)
        END
      )) ^
      (365.0 / SUM(diff_days))) - 1), 0)
      AS irr
    SQL
  end

  def select_pnl
    <<~SQL
      DATE_TRUNC('month', date) AS month,
      SUM(CASE WHEN transfers_cents > 0 THEN transfers_cents ELSE 0 END) AS deposits,
      SUM(CASE WHEN transfers_cents < 0 THEN transfers_cents ELSE 0 END) AS withdrawals,
      SUM(diff_cents) AS earnings
    SQL
  end

  def create_monthly_pnl_array(results, last_balance)
    initial_balance = BigDecimal(last_balance)
    results.map do |row|
      result = %i[deposits withdrawals earnings].map { |v| [v, BigDecimal(row.send(v))] }.to_h
      final_balance = initial_balance
      initial_balance = final_balance - result.values.reduce(&:+)
      result.map { |k, v| [k, cents_to_decimal(v)] }.to_h.merge({
        month: row.month.strftime("%Y-%m"),
        initial_balance: cents_to_decimal(initial_balance),
        final_balance: cents_to_decimal(final_balance)
      })
    end
  end
end
