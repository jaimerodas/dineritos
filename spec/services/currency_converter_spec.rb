# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrencyConverter do
  fixtures :users
  let(:user) { users(:test_user) }
  let(:mxn_account) { Account.create!(name: "MXN Account", currency: "MXN", user: user) }
  let(:usd_account) { Account.create!(name: "USD Account", currency: "USD", user: user) }

  describe ".to_mxn" do
    context "when balance is already in MXN" do
      let(:mxn_balance) do
        Balance.create!(
          account: mxn_account,
          date: Date.current,
          amount_cents: 1000,
          transfers_cents: 200,
          currency: "MXN",
          validated: true
        )
      end

      it "returns the original balance" do
        result = described_class.to_mxn(mxn_balance)
        expect(result).to eq(mxn_balance)
      end
    end

    context "when balance is in a foreign currency" do
      let(:usd_balance) do
        Balance.create!(
          account: usd_account,
          date: Date.current,
          amount_cents: 1000, # 10 USD
          transfers_cents: 200, # 2 USD
          currency: "USD",
          validated: true
        )
      end

      before do
        # Stub exchange rate
        fake_rate = instance_double("CurrencyRate", rate_subcents: 19_500_000) # 19.5 MXN per USD
        allow(CurrencyRate).to receive(:find_or_create_by).and_return(fake_rate)
      end

      it "creates or updates an MXN balance with converted amounts" do
        # Ensure no MXN balance exists first
        expect(Balance.where(account: usd_account, currency: "MXN", date: Date.current).count).to eq(0)

        # Convert balance
        mxn_balance = described_class.to_mxn(usd_balance)

        # Check that MXN balance was created with correct values
        expect(mxn_balance).to be_persisted
        expect(mxn_balance.account).to eq(usd_account)
        expect(mxn_balance.date).to eq(usd_balance.date)
        expect(mxn_balance.currency).to eq("MXN")
        expect(mxn_balance.amount_cents).to eq(19_500) # 10 USD * 19.5 = 195 MXN
        expect(mxn_balance.transfers_cents).to eq(3_900) # 2 USD * 19.5 = 39 MXN
        expect(mxn_balance.validated).to eq(true)
      end

      it "updates an existing MXN balance if one exists" do
        # Create an existing MXN balance
        existing_balance = Balance.create!(
          account: usd_account,
          date: Date.current,
          amount_cents: 15_000, # Old value: 150 MXN
          transfers_cents: 3_000, # Old value: 30 MXN
          currency: "MXN",
          validated: false
        )

        # Convert balance
        result = described_class.to_mxn(usd_balance)

        # Should update the existing balance
        expect(result.id).to eq(existing_balance.id)
        expect(result.amount_cents).to eq(19_500) # New value: 195 MXN
        expect(result.transfers_cents).to eq(3_900) # New value: 39 MXN
        expect(result.validated).to eq(true) # Updated from false
      end
    end
  end

  describe ".exchange_rate_for" do
    let(:usd_balance) do
      Balance.create!(
        account: usd_account,
        date: Date.current,
        amount_cents: 1000,
        transfers_cents: 0,
        currency: "USD"
      )
    end

    let(:mxn_balance) do
      Balance.create!(
        account: mxn_account,
        date: Date.current,
        amount_cents: 1000,
        transfers_cents: 0,
        currency: "MXN"
      )
    end

    before do
      # Stub CurrencyRate
      fake_rate = instance_double("CurrencyRate", rate_subcents: 19_500_000)
      allow(CurrencyRate).to receive(:find_or_create_by).and_return(fake_rate)
    end

    it "returns 1.0 for MXN currency" do
      expect(described_class.exchange_rate_for(mxn_balance)).to eq(1.0)
    end

    it "returns the correct exchange rate for foreign currency" do
      expect(described_class.exchange_rate_for(usd_balance)).to eq(19.5)
    end
  end

  describe ".all_to_mxn" do
    let(:balances) do
      [
        Balance.create!(account: mxn_account, date: Date.current, amount_cents: 1000, transfers_cents: 0, currency: "MXN"),
        Balance.create!(account: usd_account, date: Date.current, amount_cents: 1000, transfers_cents: 0, currency: "USD")
      ]
    end

    before do
      # Stub exchange rate
      fake_rate = instance_double("CurrencyRate", rate_subcents: 19_500_000)
      allow(CurrencyRate).to receive(:find_or_create_by).and_return(fake_rate)
    end

    it "converts all balances to MXN" do
      results = described_class.all_to_mxn(balances)

      expect(results.size).to eq(2)
      expect(results[0].currency).to eq("MXN")
      expect(results[1].currency).to eq("MXN")
    end
  end
end
