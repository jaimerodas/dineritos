class UpdateAllAccounts
  def self.run
    new.run
  end

  def initialize
  end

  def run
    process_accounts.then { |summary| send_report(summary) }
  end

  private

  def accounts
    @accounts ||= Account.updateable
  end

  def last_recorded_total_from(account)
    date = account.user.totals.order(date: :desc).limit(1).first&.date
    return 0 unless date
    account.balances.find_by(date: date)&.amount&.to_d || 0
  end

  def process_accounts
    accounts.map do |account|
      response = {
        name: account.name,
        last_recorded_balance: BigDecimal(last_recorded_total_from(account)),
        previous_balance: BigDecimal(account.last_amount.amount.to_d),
      }

      begin
        response[:current_balance] = account.latest_balance(force: true)
      rescue
        response[:error] = true
      end

      response
    end
  end

  def send_report(summary)
    ServicesMailer.daily_update(summary).deliver_now
  end
end
