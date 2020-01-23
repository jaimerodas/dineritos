class UpdateBalance
  def self.run(balance:, params:)
    new(balance: balance, params: params).run
  end

  def initialize(balance:, params:)
    @balance = balance
    @params = params
    @should_resend_email = false
  end

  attr_reader :params
  attr_accessor :balance, :should_resend_email

  def run
    balance.assign_attributes(params)
    should_resend_email = balance.date == Date.today && balance.transfers_cents_changed?
    result = balance.save
    ServicesMailer.daily_update(balance.account.user).deliver_now if should_resend_email
    result
  end
end
