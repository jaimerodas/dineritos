class EarningsReport
  def self.for(user)
    new(user)
  end

  def initialize(user)
    @user = user
  end

  attr_reader :user

  def details
    @details ||= combine(
      current: current_balances,
      day: earnings_in_the_last(1.day),
      week: earnings_in_the_last(1.week),
      month: earnings_in_the_last(1.month)
    )
  end

  def totals
    @totals ||= details.each_with_object(totals_hash) { |(account, report), result|
      %i[current day week month].each do |period|
        result[period] += report.fetch(period, BigDecimal("0"))
      end
    }
  end

  private

  def current_balances
    user.accounts.left_joins(:balances)
      .select(
        "DISTINCT ON (accounts.name) accounts.name",
        "balances.amount_cents / 100.0 amount",
        "balances.date"
      )
      .where("balances.currency": "MXN")
      .order("accounts.name": :asc, "balances.date": :desc)
      .map { |account| [account.name, BigDecimal(account.amount.to_s)] }.to_h
  end

  def earnings_in_the_last(period)
    user.balances.joins(:account)
      .select("accounts.name, SUM(diff_cents) AS diff_cents")
      .where("balances.currency": "MXN")
      .where.not("balances.diff_cents": nil)
      .where("balances.date > ?", period.ago.to_date)
      .group("accounts.name").order("accounts.name": :asc)
      .map { |balance| [balance.name, BigDecimal(balance.diff.to_s)] }.to_h
  end

  def combine(reports)
    reports.each_with_object({}) do |(period, report), result|
      report.each do |account, balance|
        result[account] ||= {}
        result[account][period] = balance
      end
    end
  end

  def totals_hash
    {current: BigDecimal("0"), day: BigDecimal("0"), week: BigDecimal("0"), month: BigDecimal("0")}
  end
end
