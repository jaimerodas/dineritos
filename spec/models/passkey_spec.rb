require 'rails_helper'

RSpec.describe Passkey, type: :model do
  let(:user) { User.create!(email: 'x@example.com') }
  subject do
    described_class.new(
      nickname: 'Device',
      external_id: SecureRandom.base64,
      public_key: 'pubkey',
      sign_count: 0,
      user: user
    )
  end

  it 'is valid with all attributes' do
    expect(subject).to be_valid
  end

  %i[nickname external_id public_key sign_count].each do |attr|
    it "is invalid without #{attr}" do
      subject.send("#{attr}=", nil)
      expect(subject).not_to be_valid
    end
  end

  it 'belongs to user' do
    assoc = described_class.reflect_on_association(:user)
    expect(assoc.macro).to eq(:belongs_to)
  end

  it 'validates uniqueness of external_id' do
    subject.save!
    duplicate = described_class.new(
      nickname: subject.nickname,
      external_id: subject.external_id,
      public_key: subject.public_key,
      sign_count: subject.sign_count,
      user: subject.user
    )
    expect(duplicate).not_to be_valid
    # error details should include :taken for external_id
    errors = duplicate.errors.details[:external_id]
    expect(errors.map { |h| h[:error] }).to include(:taken)
  end
end