require 'rails_helper'

RSpec.describe Account, type: :model do
  let(:user) { User.create!(email: 'test@example.com') }

  subject { described_class.new(name: 'Acct1', currency: 'MXN', user: user) }

  it 'is valid with valid attributes' do
    expect(subject).to be_valid
  end

  it 'is invalid without a name' do
    subject.name = nil
    expect(subject).not_to be_valid
  end

  it 'belongs to user' do
    assoc = described_class.reflect_on_association(:user)
    expect(assoc.macro).to eq(:belongs_to)
  end

  it 'has many balances' do
    assoc = described_class.reflect_on_association(:balances)
    expect(assoc.macro).to eq(:has_many)
  end

  describe '#last_amount' do
    it 'returns a Balance instance when none exist' do
      acc = described_class.create!(name: 'X', currency: 'MXN', user: user)
      ba = acc.last_amount
      expect(ba).to be_a(Balance)
    end
  end
end