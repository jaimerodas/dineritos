class UpdateAllAccounts
  def self.run(users: User.all, mailer_service: ServicesMailer)
    new(users: users, mailer_service: mailer_service).run
  end

  def initialize(users: User.all, mailer_service: ServicesMailer, max_retries: 5, retry_delay: 5)
    @users = users
    @mailer_service = mailer_service
    @max_retries = max_retries
    @retry_delay = retry_delay
    @errors = []
    @actions = []
  end

  attr_accessor :errors, :actions

  def run
    @users.each do |user|
      process_accounts_for(user)
      send_report_for(user) if should_send_report?(user)
    end

    {processed: @users.count, errors: errors.size, actions: actions.size}
  end

  private

  def process_accounts_for(user)
    update_active_accounts(user.accounts.active)
    update_balances(user.accounts.updateable)
  end

  def update_active_accounts(accounts)
    accounts.each do |account|
      last_balance = account.last_amount
      account.balances
        .find_or_initialize_by(date: Date.current, currency: account.currency)
        .update(amount_cents: last_balance.amount_cents)
    end
  end

  def update_balances(accounts)
    accounts.each { |account| update_account(account) }
  end

  def update_account(account, retries: @max_retries)
    account.latest_balance(force: true)
  rescue => error
    errors.push(account: account.name, error: error.class.name, message: error.message)
    if retries > 0
      sleep @retry_delay
      update_account(account, retries: retries - 1)
    end
  end

  def calculate_account_actions_for(user)
    user.accounts.updateable.each do |account|
      next unless account.can_be_reset?
      actions.push(account: account, action: :reset)
    end
  end

  def should_send_report?(user)
    user.settings && user.settings["daily_email"]
  end

  def send_report_for(user)
    calculate_account_actions_for(user)
    @mailer_service.new_daily_update(user, errors: errors.uniq, actions: actions).deliver_now
  end
end
