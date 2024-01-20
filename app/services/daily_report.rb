class DailyReport
  def self.for(user, date, errors = [])
    new(user, date, errors)
  end

  def initialize(user, date, errors = [])
    @user = user
    @date = date
    @errors_raw = errors
  end

  attr_reader :user, :date, :errors_raw

  def total
    user.balances
      .select("SUM(amount_cents) as amount_cents")
      .where("balances.currency": "MXN")
      .where("balances.date = ?", date)
      .to_a.first.amount_cents
      .then {|i| BigDecimal(i.to_s) / 100.0 }
  end

  def todays_exchange_rate
    @todays_exchange_rate ||= exchange_rate_on(date)
  end

  def day
    @day ||= earnings_in_the_last(1.day)
  end

  def day_usd
    balance_in_usd * (todays_exchange_rate - day_exchange_rate)
  end

  def day_exchange_rate
    @day_exchange_rate ||= exchange_rate_on(date - 1.day)
  end

  def month
    @month ||= earnings_in_the_last(1.month)
  end

  def month_usd
    balance_in_usd * (todays_exchange_rate - month_exchange_rate)
  end

  def month_exchange_rate
    @month_exchange_rate ||= exchange_rate_on(date - 1.month)
  end

  def errors
    errors_raw
  end

  private

  def earnings_in_the_last(period)
    user.balances.select("SUM(diff_cents) as diff_cents")
      .where("balances.currency": "MXN")
      .where.not("balances.diff_cents": nil)
      .where("balances.date > ?", (date - period).to_date)
      .to_a.first.diff_cents
      .then {|i| BigDecimal(i.to_s) / 100.0 }
  end

  def balance_in_usd
    @balance_in_usd ||= user.balances
      .select("SUM(amount_cents) as amount_cents")
      .where("balances.currency": "USD")
      .where("balances.date = ?", date)
      .to_a.first.amount_cents
      .then {|i| BigDecimal(i.to_s) / 100.0 }
  end

  def exchange_rate_on(date)
    BigDecimal(CurrencyRate.find_by(date: date, currency: "USD").rate_subcents.to_s) / 1000000.0
  end
end
