class UpdateAllAccounts
  def self.run
    new.run
  end

  def initialize
  end

  def run
    process_accounts
      .then { |summary| send_report(summary) }
  end

  private

  def accounts
    @accounts ||= Account.updateable
  end

  def process_accounts
    accounts.map do |account|
      name = account.name
      begin
        {
          name: name,
          previous_balance: account.last_balance,
          current_balance: account.latest_balance(force: true),
        }
      rescue
        {name: name, error: true}
      end
    end
  end

  def send_report(summary)
    ServicesMailer.daily_update(summary).deliver_now
  end
end
