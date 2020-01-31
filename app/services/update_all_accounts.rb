class UpdateAllAccounts
  def self.run
    new.run
  end

  def initialize
  end

  def run
    User.all.each do |user|
      process_accounts_for(user)
      ServicesMailer.daily_update(user).deliver_now
    end
  end

  private

  def process_accounts_for(user)
    user.accounts.updateable.each { |account| update_account(account) }
  end

  def update_account(account)
    tries ||= 5
    account.latest_balance(force: true)
    raise
  rescue
    return if (tries -= 1) == 0
    sleep 5
    retry
  end
end
