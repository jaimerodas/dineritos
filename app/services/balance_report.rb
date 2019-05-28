class BalanceReport
  def self.latest
    new(BalanceDate.select(:id).order(date: :desc).limit(2).map(&:id))
  end

  def initialize(dates)
    @dates = dates
  end

  attr_reader :dates

  def date
    @date ||= total.date
  end

  def total
    @total ||= Total.select("*").from(totals).find_by("bid = ?", dates.first)
  end

  def totals
    @totals ||= Total.joins(:balance_date).where("balance_dates.id": dates).select(total_sql)
  end

  def accounts
    @accounts ||= Balance.select("*").from(
      Balance.joins(:balance_date, :account)
        .where("balance_dates.id": dates)
        .select(<<~SQL
          accounts.name,
          balances.amount_cents,
          (
            coalesce(
              balances.amount_cents - lag(balances.amount_cents, -1)
                over (partition by accounts.name order by balance_dates.date desc),
              balances.amount_cents
            )
          ) / 100.0 diff,
          balance_dates.id bid,
          accounts.id aid
        SQL
               )
    ).where("bid = ?", dates.first).order(aid: :asc)
  end

  private

  def total_sql
    <<~SQL
      totals.amount_cents,
      (
        coalesce(
          totals.amount_cents - lag(totals.amount_cents, -1)
            over (order by balance_dates.date desc),
          totals.amount_cents
        )
      ) / 100.0 diff,
      balance_dates.id bid,
      balance_dates.date
    SQL
  end
end