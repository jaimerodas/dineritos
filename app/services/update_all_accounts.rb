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
      if user.settings && user.settings["daily_email"]
        ServicesMailer.daily_update(user, errors: errors.uniq).deliver_now
      end
    end
  end

  private

  def process_accounts_for(user)
    # 1. Crear saldos nuevos para todas las cuentas
    user.accounts.active.each do |account|
      last_balance = account.last_amount
      account.balances
        .find_or_initialize_by(date: Date.current, currency: account.currency)
        .update(amount_cents: last_balance.amount_cents)
    end

    # 2. Ir y buscar saldos nuevos para las que son actualizables
    user.accounts.updateable.each { |account| update_account(account) }
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
end
