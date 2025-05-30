class HistoricInvestmentData
  include Reports::Helpers::PeriodHelper

  def self.for(user, period: "past_year")
    new(user, period)
  end

  def initialize(user, period_string)
    @period_string = period_string
    super
  end

  attr_reader :user, :period

  def data
    {accounts: account_details, balances: balances}
  end

  def latest_date
    @latest_date ||= Date.parse(balances.last.fetch(:date))
  end

  def latest_total
    @latest_total ||= balances.last.except(:date).values.sum
  end

  private

  def balances
    @balances ||= begin
      empty = ids_with_positive_balance.zip(Array.new(ids_with_positive_balance.size, 0)).to_h
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
    @accounts ||= user.accounts.order(:id)
  end

  def account_ids
    @account_ids ||= accounts.pluck(:id)
  end

  def account_details
    accounts.select(:id, :name)
      .where(id: ids_with_positive_balance)
      .map { |account| [account.id, {name: account.name, url: "/cuentas/#{account.id}"}] }
      .to_h
  end

  def data_from_db
    user.balances
      .select(:date, :account_id, :amount_cents)
      .where(currency: "MXN")
      .where(date: period, account_id: ids_with_positive_balance)
      .order(:date, :account_id)
  end

  def ids_with_positive_balance
    @ids_with_positive_balance ||= user.balances
      .group(:account_id)
      .select(:account_id, "max(balances.amount_cents) max")
      .where(currency: "MXN")
      .where(date: period, account_id: account_ids)
      .filter { |d| d.max > 0 }
      .map { |d| d.account_id }
      .sort
  end
end
