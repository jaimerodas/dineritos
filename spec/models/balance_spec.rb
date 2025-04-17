require "rails_helper"

RSpec.describe Balance, type: :model do
  let(:user) { User.create!(email: "u@example.com") }
  let(:account) { Account.create!(name: "A", currency: "MXN", user: user) }
  let!(:b1) { Balance.create!(account: account, date: Date.yesterday, amount_cents: 1000, transfers_cents: 0, currency: "MXN", validated: true) }
  let!(:b2) { Balance.create!(account: account, date: Date.today, amount_cents: 1500, transfers_cents: 200, currency: "MXN", validated: false) }

  it "belongs to account" do
    assoc = described_class.reflect_on_association(:account)
    expect(assoc.macro).to eq(:belongs_to)
  end

  describe "diff calculation" do
    it "computes diff_cents and diff_days on save" do
      expect(b2.diff_cents).to eq(1500 - 200 - 1000)
      expect(b2.diff_days).to eq((Date.today - Date.yesterday).to_i)
    end
  end

  describe ".earliest_date and .latest_date" do
    it "returns correct earliest and latest dates" do
      expect(Balance.earliest_date).to eq(Date.yesterday)
      expect(Balance.latest_date).to eq(Date.today)
    end
  end
end
