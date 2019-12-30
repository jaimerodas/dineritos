class AccountDetailReport
  def self.latest_for(user)
    new(
      user.totals.select(:date).order(date: :desc).limit(2).map(&:date)
    )
  end

  def initialize(dates)
    @dates = dates
  end

  attr_reader :dates

  def valid?
    !total.nil?
  end

  def date
    @date ||= total.date
  end

  def next_date
    @next_date ||= Total.next_date_from(date)
  end

  def prev_date
    @prev_date ||= Total.prev_date_from(date)
  end

  def total
    @total ||= totals.first
  end

  def totals
    @totals ||= Total
      .select(total_sql)
      .where(date: dates)
      .order(date: :desc)
      .limit(2)
  end

  def account(account_id)
    @account ||= Balance.joins(:account)
      .where("accounts.id": account_id)
      .select(account_sql)
      .order("balances.date": :desc)
  end

  def accounts
    @accounts ||= Balance.select(all_fields_and_percent).from(
      Balance.joins(:account)
        .select(account_sql)
        .order(date: :desc)
        .where(date: dates)
    ).where("date = ?", dates.first).order(name: :asc)
  end

  private

  def all_fields_and_percent
    <<~SQL
      *,
      amount_cents * 1.00 / sum(amount_cents) over () percent
    SQL
  end

  def total_sql
    <<~SQL
      amount_cents,
      (
        coalesce(
          amount_cents - lag(amount_cents, -1)
            over (order by date desc),
          amount_cents
        )
      ) / 100.0 difference,
      date
    SQL
  end

  def account_sql
    <<~SQL
      accounts.name,
      balances.amount_cents,
      (
        coalesce(
          balances.amount_cents - lag(balances.amount_cents, -1)
            over (partition by accounts.name order by balances.date desc),
          balances.amount_cents
        )
      ) / 100.0 difference,
      balances.date,
      accounts.id aid
    SQL
  end
end
