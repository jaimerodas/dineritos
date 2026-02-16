class Reports::PortfolioStatement
  include Reports::Helpers::PeriodHelper
  include CurrencyConversion

  def initialize(user, period_string)
    @period_string = period_string
    super
  end

  attr_reader :period_string

  # Per-account breakdown in each account's base currency
  def account_lines
    @account_lines ||= Account
      .select(:id, :name, :currency)
      .select(decimalized("initial_balance", "starting_balance"))
      .select(decimalized("SUM(CASE WHEN transfers_cents > 0 THEN transfers_cents ELSE 0 END) - CASE WHEN initial_transfer > 0 THEN initial_transfer ELSE 0 END", "deposits"))
      .select(decimalized("SUM(CASE WHEN transfers_cents < 0 THEN transfers_cents ELSE 0 END) - CASE WHEN initial_transfer < 0 THEN initial_transfer ELSE 0 END", "withdrawals"))
      .select(decimalized("SUM(diff_cents) - initial_diff", "earnings"))
      .select(decimalized("initial_balance - initial_transfer - initial_diff + SUM(transfers_cents) + SUM(diff_cents)", "final_balance"))
      .from(account_balances_in_period)
      .group(:id, :name, :currency, :initial_balance, :initial_transfer, :initial_diff)
      .having(<<~SQL.squish)
        initial_balance != 0
        OR initial_balance - initial_transfer - initial_diff + SUM(transfers_cents) + SUM(diff_cents) != 0
        OR SUM(transfers_cents) != 0
        OR SUM(diff_cents) != 0
      SQL
      .order(currency: :asc, name: :asc)
  end

  # Grand totals per currency
  def currency_totals
    @currency_totals ||= account_lines
      .group_by(&:currency)
      .transform_values do |lines|
        {
          starting_balance: lines.sum { |l| BigDecimal(l.starting_balance.to_s) },
          deposits: lines.sum { |l| BigDecimal(l.deposits.to_s) },
          withdrawals: lines.sum { |l| BigDecimal(l.withdrawals.to_s) },
          earnings: lines.sum { |l| BigDecimal(l.earnings.to_s) },
          final_balance: lines.sum { |l| BigDecimal(l.final_balance.to_s) }
        }
      end
  end

  # Exchange rates at period start and end for non-MXN currencies
  def exchange_rates
    @exchange_rates ||= begin
      currencies = user.accounts.active.where.not(currency: "MXN").distinct.pluck(:currency)
      currencies.map do |curr|
        start_rate = find_rate(curr, period.first)
        end_rate = find_rate(curr, period.last)
        {currency: curr, start_rate: start_rate, end_rate: end_rate}
      end
    end
  end

  # Aggregated start/end balance in MXN across all accounts
  def mxn_totals
    @mxn_totals ||= begin
      account_ids = user.accounts.active.pluck(:id)
      base = Balance.where(account_id: account_ids, currency: "MXN", date: period)

      {
        starting_balance: sum_boundary_balances(base, :asc),
        final_balance: sum_boundary_balances(base, :desc)
      }
    end
  end

  # Breakdown of MXN totals: transfers, earnings, FX effects
  def mxn_breakdown
    @mxn_breakdown ||= begin
      mxn = currency_totals["MXN"] || empty_totals
      usd = currency_totals["USD"] || empty_totals
      usd_end_rate = BigDecimal(
        (exchange_rates.find { |r| r[:currency] == "USD" }&.dig(:end_rate) || 0).to_s
      )

      transferred_mxn = mxn[:deposits] + mxn[:withdrawals]
      earnings_mxn = mxn[:earnings]
      transferred_usd_mxn = (usd[:deposits] + usd[:withdrawals]) * usd_end_rate
      earnings_usd_mxn = usd[:earnings] * usd_end_rate
      fx_gain_loss = mxn_totals[:final_balance] - mxn_totals[:starting_balance] -
        transferred_mxn - earnings_mxn - transferred_usd_mxn - earnings_usd_mxn

      {
        transferred_mxn: transferred_mxn,
        earnings_mxn: earnings_mxn,
        transferred_usd_mxn: transferred_usd_mxn,
        earnings_usd_mxn: earnings_usd_mxn,
        fx_gain_loss: fx_gain_loss
      }
    end
  end

  def multi_day_period?
    period.last > period.first
  end

  private

  def empty_totals
    {starting_balance: BigDecimal(0), deposits: BigDecimal(0),
     withdrawals: BigDecimal(0), earnings: BigDecimal(0),
     final_balance: BigDecimal(0)}
  end

  def account_balances_in_period
    user.accounts.active.joins(:balances)
      .select(
        "accounts.id", "accounts.name", "accounts.currency",
        first_value("amount_cents", "initial_balance"),
        first_value("transfers_cents", "initial_transfer"),
        first_value("diff_cents", "initial_diff"),
        "balances.transfers_cents", "balances.diff_cents", "balances.date"
      )
      .where("balances.currency = accounts.currency")
      .where("balances.date": period)
  end

  def first_value(column, key)
    "COALESCE(
      FIRST_VALUE(balances.#{column})
      OVER (PARTITION BY accounts.id ORDER BY balances.date ASC)
    , 0) AS #{key}"
  end

  def find_rate(currency, date)
    rate = CurrencyRate.find_by(date: date, currency: currency)
    rate ||= CurrencyRate.where(currency: currency).where("date <= ?", date).order(date: :desc).first
    rate&.rate
  end

  def sum_boundary_balances(base_query, order)
    ranked_sql = base_query
      .select("balances.amount_cents, ROW_NUMBER() OVER (PARTITION BY balances.account_id ORDER BY balances.date #{order}) AS rank")
      .to_sql

    result = ActiveRecord::Base.connection.select_value(
      "SELECT SUM(amount_cents) FROM (#{ranked_sql}) ranked WHERE ranked.rank = 1"
    )

    cents_to_decimal(result || 0)
  end
end
