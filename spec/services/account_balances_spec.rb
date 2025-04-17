require 'date'
# Provide Date.current for testing
unless Date.respond_to?(:current)
  class Date
    def self.current
      today
    end
    # Add yesterday for testing
    def yesterday
      self - 1
    end
    # Add beginning_of_month for testing
    def beginning_of_month
      Date.new(year, month, 1)
    end
  end
end
require 'bigdecimal'
require_relative '../../app/services/account_balances'

RSpec.describe AccountBalances do
  # A minimal FakeRelation to support where/ order chaining
  # A minimal in-memory relation that supports where and order
  class FakeRelation < Array
    def where(cond, *args)
      results = if cond.is_a?(Hash)
        key, value = cond.first
        select { |b| b.send(key) == value }
      elsif cond.to_s.start_with?("DATE_TRUNC") && args.first.is_a?(Date)
        target = args.first
        select { |b| Date.new(b.date.year, b.date.month, 1) == Date.new(target.year, target.month, 1) }
      else
        to_a
      end
      # wrap results back into FakeRelation so chaining continues
      # create a new FakeRelation populated with results
      FakeRelation[*results]
    end
    def order(*); self; end
  end

  # Add Integer#month for testing
  class Integer
    def month
      self
    end
  end
  # Dummy balance struct for testing with required attributes
  DummyBalance = Struct.new(:date, :currency, :diff, :transfers, :diff_days, :amount)

  let(:user) { Object.new }
  let(:balances_array) do
    # define balances as a FakeRelation containing specific FakeBalance entries
    FakeRelation[
      DummyBalance.new(Date.new(2021,1,1),  'USD',  10,  5,  1, 100.0),
      DummyBalance.new(Date.new(2021,1,15), 'USD',  20, 10, 14, 200.0),
      DummyBalance.new(Date.new(2021,2,1),  'USD',  30, 15, 17, 300.0)
    ]
  end
  let(:account) do
    double('Account',
      user: user,
      currency: 'USD',
      name: 'MyAcct',
      balances: balances_array
    )
  end

  describe '#initialize' do
    it 'sets account and month when authorized' do
      ab = described_class.new(user: user, account: account, month: '2021-01')
      expect(ab.account).to eq(account)
      expect(ab.month).to eq('2021-01')
    end

    it 'raises if user unauthorized' do
      other = Object.new
      expect {
        described_class.new(user: other, account: account, month: '2021-01')
      }.to raise_error(RuntimeError)
    end
  end

  subject { described_class.new(user: user, account: account, month: '2021-01') }

  describe '#parsed_date' do
    it 'parses month into a date at first of month' do
      expect(subject.parsed_date).to eq(Date.new(2021,1,1))
    end
  end

  describe '#account_name' do
    it 'returns the account name' do
      expect(subject.account_name).to eq('MyAcct')
    end
  end

  describe '#balances' do
    it 'filters balances to the given month and currency' do
      # Only two balances in Jan 2021
      result = subject.balances
      expect(result.size).to eq(2)
      expect(result.map(&:date)).to match_array([Date.new(2021,1,1), Date.new(2021,1,15)])
    end
  end

  # next_month behavior depends on ActiveSupport extensions (not tested here)

  describe '#prev_month' do
    before do
      # stub initial_balance_date to '2020-12'
      allow(subject).to receive(:initial_balance_date).and_return('2020-12')
    end
    it 'returns the previous month beginning' do
      expect(subject.prev_month).to eq(Date.new(2020,12,1))
    end

    it 'returns nil when at initial_balance_date' do
      allow(subject).to receive(:initial_balance_date).and_return('2021-01')
      expect(subject.prev_month).to be_nil
    end
  end

  describe 'summaries' do
    it 'sums earnings from balances' do
      expect(subject.earnings).to eq(10 + 20)
    end

    it 'sums transfers from balances' do
      expect(subject.transfers).to eq(5 + 10)
    end

    it 'sums diff_days from balances' do
      expect(subject.diff_days).to eq(1 + 14)
    end

    it 'calculates irr correctly' do
      # ror1 = 10/(100-10-5)=10/85; ror2=20/(200-20-10)=20/170; sum=10/85+20/170=0.117647+0.117647=0.235294
      # diff_days sum=1+14=15; irr = (1+0.235294)**(365/15)-1
      expected_ror = 10.0/85 + 20.0/170
      expected_irr = (1 + expected_ror)**(365.0/15) - 1
      expect(subject.irr).to be_within(1e-6).of(expected_irr)
    end
  end
end
