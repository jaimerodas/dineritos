class BalanceReport
  def initialize(user:, account: "all", page: 1)
    @user = user
    @account_id = account
    @page = page
  end

  attr_reader :account_id, :user, :page

  def rows
    model = (account_id == "all" ? :total : :balances)
    report = user.balance_dates.select(:amount_cents, :date).joins(model)

    unless account_id == "all"
      report = report.where("balances.account_id": account_id)
    end

    report.paginate(page: page, per_page: 10).order(date: :desc)
  end

  def account
    @account ||= user.accounts.find(account_id)
  end

  def account_name
    account.name
  end
end
