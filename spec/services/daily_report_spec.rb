# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyReport do
  # This test focuses on key functionality without relying on Balance and CurrencyExchange
  # which have caused test issues

  let(:user) { User.create!(email: "test@example.com") }
  let(:today) { Date.current }
  let(:yesterday) { today - 1.day }
  let(:month_ago) { today - 1.month }

  # Mock exchange_rate_on so it doesn't access the database or call CurrencyExchange
  before(:each) do
    # Force the method to use our fixed values instead of database values
    # Add specific values with exact precision that won't change
    allow_any_instance_of(DailyReport).to receive(:exchange_rate_on).with(today).and_return(BigDecimal("20.0"))
    allow_any_instance_of(DailyReport).to receive(:exchange_rate_on).with(yesterday).and_return(BigDecimal("19.5"))
    allow_any_instance_of(DailyReport).to receive(:exchange_rate_on).with(month_ago).and_return(BigDecimal("19.0"))
  end

  context "basic instantiation" do
    it "creates a report instance" do
      report = DailyReport.for(user, today)
      expect(report).to be_a(DailyReport)
      expect(report.user).to eq(user)
      expect(report.date).to eq(today)
    end

    it "accepts date as string" do
      date_string = today.to_s
      report = DailyReport.for(user, date_string)
      expect(report.date).to eq(today)
    end

    it "accepts errors parameter" do
      errors = [{account: "Test", error: "Error", message: "Test error"}]
      report = DailyReport.for(user, today, errors)
      expect(report.errors_raw).to eq(errors)
    end
  end

  context "exchange rates" do
    subject { DailyReport.for(user, today) }

    before(:each) do
      # Reset any cached values to ensure we're testing with a clean state
      subject.instance_variable_set(:@todays_exchange_rate, nil)
      subject.instance_variable_set(:@day_exchange_rate, nil)
      subject.instance_variable_set(:@month_exchange_rate, nil)
    end

    it "returns exchange rates for different dates" do
      # Test each exchange rate individually with explicit stubbing
      # for this specific test only
      allow(subject).to receive(:exchange_rate_on).with(today).and_return(BigDecimal("20.0"))
      expect(subject.todays_exchange_rate).to eq(BigDecimal("20.0"))

      allow(subject).to receive(:exchange_rate_on).with(yesterday).and_return(BigDecimal("19.5"))
      expect(subject.day_exchange_rate).to eq(BigDecimal("19.5"))

      allow(subject).to receive(:exchange_rate_on).with(month_ago).and_return(BigDecimal("19.0"))
      expect(subject.month_exchange_rate).to eq(BigDecimal("19.0"))
    end
  end

  context "error handling" do
    subject { DailyReport.for(user, today) }

    it "filters validated account errors" do
      # Create test account and balance
      account = user.accounts.create!(name: "Test Account", currency: "MXN")
      Balance.create!(
        account: account,
        date: today,
        amount_cents: 1000,
        transfers_cents: 0,
        currency: "MXN",
        validated: true
      )

      # Create errors with both validated and non-validated accounts
      errors = [
        {account: "Test Account", error: "Error", message: "Should be filtered out"},
        {account: "Another Account", error: "Error", message: "Should remain"}
      ]

      report = DailyReport.for(user, today, errors)
      filtered_errors = report.errors

      # The error for Test Account should be filtered out as it has a validated balance
      expect(filtered_errors.size).to eq(1)
      expect(filtered_errors.first[:account]).to eq("Another Account")
    end

    it "handles missing exchange rates gracefully" do
      allow(subject).to receive(:todays_exchange_rate).and_return(nil)
      allow(subject).to receive(:day_exchange_rate).and_return(nil)

      # Should not raise an error and return zero
      expect { subject.day_usd }.not_to raise_error
      expect(subject.day_usd).to eq(BigDecimal("0.0"))
    end
  end

  context "with mocked balance methods" do
    subject { DailyReport.for(user, today) }

    before(:each) do
      # Force reset any cached values to ensure clean state
      subject.instance_variable_set(:@todays_exchange_rate, nil)
      subject.instance_variable_set(:@day_exchange_rate, nil)
      subject.instance_variable_set(:@month_exchange_rate, nil)
      subject.instance_variable_set(:@balance_in_usd, nil)

      # Force specific values for all relevant methods
      allow(subject).to receive(:balance_in_usd).and_return(BigDecimal("12.5"))

      # Explicitly override the exchange rates to avoid any test interference
      allow(subject).to receive(:todays_exchange_rate).and_return(BigDecimal("20.0"))
      allow(subject).to receive(:day_exchange_rate).and_return(BigDecimal("19.5"))
      allow(subject).to receive(:month_exchange_rate).and_return(BigDecimal("19.0"))

      # Allow the original calculations to run
      allow(subject).to receive(:day_usd).and_call_original
      allow(subject).to receive(:month_usd).and_call_original
    end

    it "calculates daily USD impact correctly" do
      # Test calculation: 12.5 USD * (20.0 - 19.5) = 12.5 * 0.5 = 6.25 MXN
      result = subject.day_usd
      expect(result).to eq(BigDecimal("6.25"))
    end

    it "calculates monthly USD impact correctly" do
      # Test calculation: 12.5 USD * (20.0 - 19.0) = 12.5 * 1.0 = 12.5 MXN
      result = subject.month_usd
      expect(result).to eq(BigDecimal("12.5"))
    end
  end
end
