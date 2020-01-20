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
    user.accounts.updateable.each do |account|
      begin
        account.latest_balance(force: true)
      rescue
        next
      end
    end
  end
end
