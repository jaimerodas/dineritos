require 'ostruct'
require 'date'
require 'bigdecimal'
require './app/services/report_helper'
require './app/services/account_report'

RSpec.describe AccountReport do
  # A minimal fake account to drive the service without ActiveRecord
  class FakeAccount
    attr_reader :name, :currency, :user, :balances
    def initialize(name:, currency:, user:, balances:)
      @name     = name
      @currency = currency
      @user     = user
      @balances = balances
    end
    # simulate last_amount(use:)
    def last_amount(use:)
      # pick latest balance matching currency (balances sorted)
      balances.select { |b| b.currency == use }.max_by(&:date) || nil
    end
  end

  let(:user) { Object.new }
  let(:earliest_date) { Date.new(2020, 1, 1) }
  let(:balances) { double('balances', earliest_date: earliest_date) }
  let(:account) do
    FakeAccount.new(
      name: 'Acct1',
      currency: 'USD',
      user: user,
      balances: balances
    )
  end

  describe '#initialize' do
    before do
      allow_any_instance_of(AccountReport)
        .to receive(:determine_period_range)
        .with('all', account)
        .and_return(earliest_date..Date.today)
    end
    it 'sets account_name, currency, and period' do
      report = AccountReport.new(user: user, account: account)
      expect(report.account_name).to eq('Acct1')
      expect(report.currency).to eq('USD')
      expect(report.period.begin).to eq(earliest_date)
      expect(report.period.end).to eq(Date.today)
    end

    it 'allows overriding currency to MXN' do
      report = AccountReport.new(user: user, account: account, currency: 'MXN')
      expect(report.currency).to eq('MXN')
    end

    it 'rejects when user does not own the account' do
      other = Object.new
      expect {
        AccountReport.new(user: other, account: account)
      }.to raise_error(ArgumentError, /Unauthorized user for this account/)
    end
  end


  describe 'financial calculations' do
    subject { AccountReport.new(user: user, account: account) }

    before do
      # stub summary and available_balances
      stub_summary = OpenStruct.new(
        earnings:    500,
        deposits:    300,
        withdrawals: -200,
        irr:         BigDecimal('0.10')
      )
      allow(subject).to receive(:summary).and_return(stub_summary)
    end

    it 'computes earnings as decimal' do
      expect(subject.earnings).to eq(5.0)
    end

    it 'computes deposits as decimal' do
      expect(subject.deposits).to eq(3.0)
    end

    it 'computes withdrawals as positive decimal' do
      expect(subject.withdrawals).to eq(2.0)
    end

    it 'computes net_transferred correctly' do
      expect(subject.net_transferred).to eq(1.0)
    end

    it 'returns irr value' do
      expect(subject.irr).to eq(BigDecimal('0.10'))
    end
  end
end
