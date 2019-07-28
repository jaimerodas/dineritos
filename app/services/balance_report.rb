class BalanceReport
  def initialize(account: "all", page: 1)
    @account_id = account
    @page = page
  end

  attr_reader :account_id, :page

  def rows
    model = account_id == "all" ? Total : Balance

    unless account_id == "all"
      model = model.where(account: account)
    end

    model.select(:amount_cents, "balance_dates.date")
      .joins(:balance_date)
      .paginate(page: page)
      .order(date: :desc)
  end

  def account
    @account ||= Account.find(account_id)
  end

  def account_name
    account.name
  end
end
