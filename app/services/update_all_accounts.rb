class UpdateAllAccounts
  def self.run
    new.run
  end

  def initialize
    @errors = []
  end

  attr_accessor :errors

  def run
    User.all.each do |user|
      process_accounts_for(user)
      ServicesMailer.daily_update(user, errors: errors.uniq).deliver_now
    end
  end

  private

  def process_accounts_for(user)
    user.accounts.updateable.each { |account| update_account(account) }
    user.accounts.foreign_currency.each { |account| update_foreign_currency_account(account) }
  end

  def update_account(account)
    tries ||= 5
    account.latest_balance(force: true)
  rescue => error
    errors.push(account: account.name, error: error.class.name, message: error.message)
    return if (tries -= 1) == 0
    sleep 5
    retry
  end

  def update_foreign_currency_account(account)
    last_balance = account.last_amount
    account.balances
      .find_or_initialize_by(date: Date.current, currency: account.currency)
      .update(amount_cents: last_balance.amount_cents)
  end
end
