class CreateTotal
  def self.from(user:, params:)
    new(user: user, params: params).run
  end

  def initialize(user:, params:)
    @user = user
    @params = params
  end

  attr_accessor :user, :params

  def run
    create_balances_from_form
    create_balances_on_bitso_accounts
    calculate_total
    deactivate_accounts
  end

  private

  def date
    @date = Date.current
  end

  def create_balances_from_form
    params[:account].each do |account_id, fields|
      balance = user.accounts.find(account_id).balances.find_or_initialize_by(date: date)
      field = fields.keys.first
      balance.public_send("#{field}=", fields.fetch(field))
      balance.save
    end
  end

  def create_balances_on_bitso_accounts
    user.accounts.bitso.each do |account|
      amount = BitsoService.current_balance_for(account)
      next if amount.zero? && !account.active?
      account.balances.create(amount: amount, date: date)
      account.update_attribute(:active, true) if !amount.zero? && !account.active?
    end
  end

  def calculate_total
    user.balances
      .where(date: date)
      .select("SUM(balances.amount_cents) as total").order(nil)[0].total
      .then { |amount_cents|
        total = user.totals.find_or_initialize_by(date: date)
        total.amount_cents = amount_cents
        total.save
      }
  end

  def deactivate_accounts
    user.balances.where(amount_cents: 0).each do |balance|
      balance.account.update(active: false)
    end
  end
end
