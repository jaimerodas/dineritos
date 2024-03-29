class UpdateBalance
  def self.run(balance:, params:)
    new(balance: balance, params: params).run
  end

  def initialize(balance:, params:)
    @balance = balance
    balance.assign_attributes(params.merge(validated: true))
    invalidated_todays_email?
    modified_history?
  end

  attr_accessor :balance

  def run
    saved_successfully = balance.save

    if saved_successfully
      resend_email if invalidated_todays_email? && user_wants_to_be_notified?
      update_financials if modified_history?
    end

    saved_successfully
  end

  private

  def invalidated_todays_email?
    @invalidated_todays_email ||= balance.date == Date.current && (
      balance.transfers_cents_changed? || balance.amount_cents_changed?
    )
  end

  def user_wants_to_be_notified?
    balance.account.user.settings && balance.account.user.settings["send_email_after_update"]
  end

  def modified_history?
    @modified_history ||= balance.date < Date.current && balance.amount_cents_changed?
  end

  def resend_email
    ServicesMailer.new_daily_update(balance.account.user).deliver_now
  end

  def update_financials
    balance.next.save
  end
end
