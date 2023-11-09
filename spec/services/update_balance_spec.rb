require "./app/services/update_balance"
require "ostruct"
require "active_support/core_ext/date"
require "active_support/isolated_execution_state"

RSpec.describe UpdateBalance do
  context "balance from today with everything changed" do
    let(:balance) { described_class.new(balance: FakeBalance.new, params: {}) }

    it "should send email" do
      expect(balance.send(:invalidated_todays_email?)).to be true
    end

    it "should not update financials" do
      expect(balance.send(:modified_history?)).to be false
    end

    it "should run successfully" do
      expect(balance.run).to be true
    end
  end

  context "balance from another day with everything changed" do
    let(:balance) { described_class.new(balance: FakeBalance.new(from_today: false), params: {}) }

    it "shouldn't send email" do
      expect(balance.send(:invalidated_todays_email?)).to be false
    end

    it "should update financials" do
      expect(balance.send(:modified_history?)).to be true
    end

    it "should run successfully" do
      expect(balance.run).to be true
    end
  end
end

class FakeBalance < OpenStruct
  def initialize(params = {})
    super({
      from_today: true,
      amount_cents_changed?: true,
      transfers_cents_changed?: true,
      save: true
    }.merge(params))
  end

  def assign_attributes(_)
  end

  def account
    OpenStruct.new(user: OpenStruct.new(settings: {send_email_after_update: true}))
  end

  def date
    from_today ? Date.current : Date.yesterday
  end

  def next
    self.class.new(from_today: true)
  end
end

class ServicesMailer
  def self.daily_update(_)
    OpenStruct.new(deliver_now: false)
  end
end
