class BalanceReport
  def initialize(user:, account: "all", page: 1)
    @user = user
    @account_id = account
    @page = page
  end

  attr_reader :account_id, :user, :page

  def rows
    report = user.public_send(model).select(:id, :amount_cents, :date)
    report = report.where("account_id": account_id) if account_set?
    report.paginate(page: page, per_page: 10).order(date: :desc)
  end

  def account
    return unless account_set?
    @account ||= user.accounts.find(account_id)
  end

  def account_name
    account.name
  end

  def account_set?
    account_id != "all"
  end

  def model
    account_set? ? "balances" : "totals"
  end
end
