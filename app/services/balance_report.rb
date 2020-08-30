class BalanceReport
  def initialize(user:, page: 1)
    @user = user
    @page = page
  end

  attr_reader :account_id, :user, :page

  def rows
    user.totals
      .select(:id, :amount_cents, :date)
      .paginate(page: page, per_page: 10).order(date: :desc)
  end

  def account
    nil
  end
end
