class DailyReport
  def self.for(user, date, errors = [])
    new(user, date, errors)
  end

  def initialize(user, date, errors = [])
    @user = user
    @date = date.is_a?(Date) ? date : date.to_date
    @errors_raw = errors
  end

  attr_reader :user, :date, :errors_raw

  def total
    user.balances
      .select("SUM(amount_cents) as amount_cents")
      .where("balances.currency": "MXN", "balances.date": date)
      .to_a.first.amount_cents
      .then { |i| BigDecimal(i.to_s) / 100.0 }
  end

  def todays_exchange_rate
    @todays_exchange_rate ||= exchange_rate_on(date)
  end

  def day
    @day ||= earnings_in_the_last(1.day)
  end

  def day_usd
    return BigDecimal("0.0") unless todays_exchange_rate && day_exchange_rate
    balance_in_usd * (todays_exchange_rate - day_exchange_rate)
  end

  def day_exchange_rate
    @day_exchange_rate ||= exchange_rate_on(date - 1.day)
  end

  def month
    @month ||= earnings_in_the_last(1.month)
  end

  def month_usd
    return BigDecimal("0.0") unless todays_exchange_rate && month_exchange_rate
    balance_in_usd * (todays_exchange_rate - month_exchange_rate)
  end

  def month_exchange_rate
    @month_exchange_rate ||= exchange_rate_on(date - 1.month)
  end

  def errors
    errors_raw.reject do |e|
      user.balances.joins(:account)
        .where(
          "balances.date": date,
          "accounts.name": e[:account],
          "balances.validated": true
        ).any?
    end
  end

  def earliest_date
    @earliest_date ||= user.balances.earliest_date
  end

  def latest_date
    @latest_date ||= user.balances.latest_date
  end

  private

  def earnings_in_the_last(period)
    user.balances.select("SUM(diff_cents) as diff_cents")
      .where("balances.currency": "MXN")
      .where.not("balances.diff_cents": nil)
      .where("balances.date > ?", (date - period).to_date)
      .where("balances.date <= ?", date)
      .to_a.first.diff_cents
      .then { |i| BigDecimal(i.to_s) / 100.0 }
  end

  def balance_in_usd
    @balance_in_usd ||= user.balances
      .select("SUM(amount_cents) as amount_cents")
      .where("balances.currency": "USD")
      .where("balances.date = ?", date)
      .to_a.first.amount_cents
      .then { |i| BigDecimal(i.to_s) / 100.0 }
  end

  def exchange_rate_on(date)
    rate = CurrencyRate.find_by(date: date, currency: "USD")
    return false unless rate
    BigDecimal(rate.rate_subcents.to_s) / 1000000.0
  end
end
