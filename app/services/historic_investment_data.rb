class HistoricInvestmentData
  def self.for(user, period: "past_year")
    new(user, period)
  end

  def initialize(user, period_string)
    @user = user
    @period_string = period_string
    @period = calculate_period_from(@period_string)
  end

  attr_reader :user, :period

  def data
    {accounts: account_details, balances: balances}
  end

  def latest_date
    @latest_date ||= Date.parse(balances.last.fetch(:date))
  end

  def latest_total
    @latest_total ||= balances.last.reject { |k, _| k == :date }.values.sum
  end

  private

  def earliest_date
    @earliest_date ||= user.balances.earliest_date
  end

  def calculate_period_from(year)
    return 1.year.ago..Date.current if year == "past_year"
    return earliest_date..Date.current if year == "all"
    year = year.to_i if year.instance_of?(String)
    Date.new(year)...Date.new(year + 1)
  end

  def balances
    @balances ||= begin
      empty = account_ids.zip(Array.new(account_ids.size, 0)).to_h
      current = -1

      data_from_db.each_with_object([]) do |balance, result|
        date = balance.date.to_s

        if result.dig(current, :date) != date
          current += 1
          result[current] = result.fetch(current - 1, empty).dup
          result[current][:date] = date
        end

        result[current][balance.account_id] = balance.amount.to_f
      end
    end
  end

  def accounts
    @accounts ||= user.accounts.where(account_type: :investment).order(:id)
  end

  def account_ids
    @account_ids ||= accounts.pluck(:id)
  end

  def account_details
    accounts.select(:id, :name)
      .map { |account| [account.id, {name: account.name, url: "/cuentas/#{account.id}"}] }
      .to_h
  end

  def data_from_db
    user.balances
      .select(:date, :account_id, :amount_cents)
      .where(currency: "MXN")
      .where(date: period, account_id: account_ids)
      .order(:date, :account_id)
  end
end
