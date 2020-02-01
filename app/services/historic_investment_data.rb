class HistoricInvestmentData
  def self.for(user)
    new(user)
  end

  def initialize(user)
    @user = user
  end

  attr_reader :user

  def to_json
    data.to_json
  end

  def latest_date
    @latest_date ||= Date.parse(data.last.fetch(:date))
  end

  def latest_total
    @latest_total ||= data.last.reject { |key, value| key == :date }.values.sum
  end

  private

  def data
    @data ||= begin
      empty = account_names.zip(Array.new(accounts.size, 0)).to_h
      current = -1

      data_from_db.each_with_object([]) do |balance, result|
        if result.dig(current, :date) != balance.date.to_s
          current += 1
          result[current] = result.fetch(current - 1, empty).dup
          result[current][:date] = balance.date.to_s
        end

        result[current][balance.name] = balance.amount.to_f
      end
    end
  end

  def accounts
    @accounts ||= user.accounts.where(account_type: :investment).select(:name, :id).order(:id)
  end

  def account_names
    accounts.map(&:name)
  end

  def account_ids
    accounts.map(&:id)
  end

  def data_from_db
    user.balances
      .select(:date, :"accounts.name", :amount_cents)
      .where("date > ?", 1.year.ago)
      .where("accounts.id": account_ids)
      .order(:date, :"accounts.name")
  end
end
