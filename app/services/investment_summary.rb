class InvestmentSummary
  include Reports::Helpers::PeriodHelper

  def self.for(user:, period: "past_year")
    new(user, period)
  end

  def initialize(user, period_string)
    @period_string = period_string
    super
  end

  def to_h
    %i[starting_balance final_balance earnings deposits withdrawals net_investment irr]
      .map { |method| [method, public_send(method).to_f] }
      .to_h
  end

  def starting_balance
    final_balance - earnings - net_investment
  end

  def final_balance
    @final_balance ||= Balance
      .select("SUM(amount_cents) AS amount_cents")
      .where("rank = 1")
      .from(ranked_balances)
      .order("1").first&.amount&.amount || 0
  end

  def earliest_year
    @earliest_year ||= earliest_date.year
  end

  def earnings
    @earnings ||= BigDecimal(period_aggregate&.earnings || 0)
  end

  def deposits
    @deposits ||= BigDecimal(period_aggregate&.deposits || 0)
  end

  def withdrawals
    @withdrawals ||= BigDecimal((period_aggregate&.withdrawals || 0) * -1)
  end

  def net_investment
    deposits - withdrawals
  end

  def irr
    IrrReport.for(user: user, period: @period_string).accumulated_irr
  end

  private

  def elegible_account_ids
    @elegible_account_ids ||= user.accounts.pluck(:id)
  end

  def period_aggregate
    @period_aggregate ||= Balance
      .select(deposits_column, withdrawals_column, earnings_column)
      .where(account_id: elegible_account_ids, date: period, currency: "MXN")
      .order("1").first
  end

  def deposits_column
    "SUM(CASE WHEN transfers_cents > 0 THEN transfers_cents ELSE 0 END) / 100.0 AS deposits"
  end

  def withdrawals_column
    "SUM(CASE WHEN transfers_cents < 0 THEN transfers_cents ELSE 0 END) / 100.0 AS withdrawals"
  end

  def earnings_column
    "SUM(diff_cents) / 100.0 AS earnings"
  end

  def rank_column
    "row_number() OVER (PARTITION BY account_id ORDER BY date DESC) AS rank"
  end

  def ranked_balances
    Balance
      .select(:amount_cents, rank_column)
      .where(account_id: elegible_account_ids, date: period, currency: "MXN")
      .order("rank")
  end
end
