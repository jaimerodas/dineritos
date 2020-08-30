class IrrReport
  def self.for(user:, period: "past_year")
    new(user, period)
  end

  def initialize(user, period_string)
    @user = user
    @period = calculate_period_from(period_string)
  end

  attr_reader :user, :period

  def accumulated_irr
    @accumulated_irr ||= begin
      rate, days = by_month.each_with_object([0, 0]) { |(_, month), result|
        result[0] += month[:diff] / month[:starting_balance]
        result[1] += month[:days]
      }

      ((1 + rate)**(365.0 / days)) - 1
    end
  end

  def by_month
    @by_month ||= begin
      prev_date = nil
      prev_final_balance = nil

      diffs.each_with_object({}) do |balance, result|
        eom = balance.month.end_of_month
        eom = Date.current if eom == Date.current.end_of_month
        month = balance.month.to_s
        final_balance = final_balances.fetch(month)

        if prev_date && prev_final_balance
          result[month] = {
            diff: balance.diff.to_f,
            transfers: (final_balance - prev_final_balance - balance.diff).to_f,
            starting_balance: prev_final_balance.to_f,
            days: prev_date ? (eom - prev_date).to_i : nil
          }
          result[month][:irr] = (1 + balance.diff / prev_final_balance)**(365.0 / result[month][:days]) - 1
        end

        prev_date = eom
        prev_final_balance = final_balance
      end
    end
  end

  def diffs
    @diffs ||= Balance
      .select("SUM(diff_cents) AS diff_cents", "DATE_TRUNC('month', date)::DATE AS month")
      .where(account_id: accounts, date: period, currency: "MXN")
      .group("2").order("2")
  end

  def final_balances
    @final_balances ||= Balance
      .select("SUM(amount_cents) AS amount_cents", "month")
      .from(ranked_balances)
      .where("rank = 1")
      .group("2").order("2")
      .map { |balance| [balance.month.to_s, balance.amount] }
      .to_h
  end

  def ranked_balances
    Balance
      .select(:amount_cents, "DATE_TRUNC('month', date)::DATE AS month", rank_column)
      .where(account_id: accounts, date: period, currency: "MXN")
      .order("2")
  end

  def rank_column
    <<~SQL
      RANK() OVER (
      	PARTITION BY account_id, DATE_TRUNC('month', date)
      	ORDER BY date DESC
      ) AS rank
    SQL
  end

  def accounts
    user.accounts.select(:id).where(account_type: :investment)
  end

  def calculate_period_from(year)
    return 1.year.ago.beginning_of_month - 1.month..Date.current if year == "past_year"
    year = year.to_i if year.is_a? String
    (Date.new(year) - 1.month)...Date.new(year + 1)
  end
end
