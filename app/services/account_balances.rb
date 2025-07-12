class AccountBalances
  include UserAuthorization

  def initialize(user:, account:, month:)
    validate_user_account!(user, account)
    @account = account
    @month = month
  end

  attr_reader :account, :month

  def balances
    @balances ||= account.balances
      .where(currency: account.currency)
      .where("DATE_TRUNC('month', balances.date) = ?", parsed_date)
      .order(date: :desc)
  end

  def starting_balance
    @starting_balance ||= balances.last.amount
  end

  def final_balance
    @final_balance ||= balances.first.amount
  end

  def account_name
    @account_name ||= account.name
  end

  def parsed_date
    @parsed_date ||= Date.parse("#{month}-01")
  end

  def next_month
    return if parsed_date == Date.current.beginning_of_month
    (parsed_date + 1.month).beginning_of_month
  end

  def prev_month
    return if month == initial_balance_date
    (parsed_date - 1.month).beginning_of_month
  end

  def initial_balance_date
    @initial_balance_date ||= account.balances
      .select(:date)
      .order(date: :asc)
      .limit(1).first
      .date.strftime("%Y-%m")
  end

  def earnings
    @earnings ||= balances.map(&:diff).compact.sum
  end

  def transfers
    @transfers ||= balances.map(&:transfers).compact.sum
  end

  def diff_days
    @diff_days ||= balances.map(&:diff_days).compact.sum
  end

  def irr
    @irr ||= balances.map { |balance|
      prev_balance = balance.amount.to_f - balance.diff.to_f - balance.transfers.to_f
      balance.diff.to_f / (prev_balance.zero? ? 1 : prev_balance)
    }.sum.then { |ror| ((1 + ror)**(365.0 / diff_days)) - 1 }
  end
end
