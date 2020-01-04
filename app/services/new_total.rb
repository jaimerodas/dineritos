class NewTotal
  def self.for(user)
    new(user)
  end

  def initialize(user)
    @user = user
  end

  attr_reader :user

  def today
    @today ||= Date.current.to_s
  end

  def latest_balances
    user.accounts.left_joins(:balances)
      .select(select_statement)
      .where(active: true)
      .where.not(account_type: 1)
      .order("accounts.id": :asc, "balances.date": :desc)
  end

  def non_editable_accounts
    user.accounts.bitso.select(:name).map(&:name)
  end

  private

  def select_statement
    <<~SQL
    DISTINCT ON (accounts.id)
    accounts.id, accounts.name, accounts.currency,
    balances.amount_cents / 100.0 AS amount,
    balances.original_amount_cents / 100.0 AS original_amount,
    balances.date
    SQL
  end
end
