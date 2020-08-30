class HistoricInvestmentData
  def self.for(user)
    new(user)
  end

  def initialize(user)
    @user = user
  end

  attr_reader :user

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
      .where("date > ?", 1.year.ago)
      .where(account_id: account_ids)
      .order(:date, :account_id)
  end
end
