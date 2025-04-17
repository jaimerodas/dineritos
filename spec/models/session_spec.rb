require "rails_helper"

RSpec.describe Session, type: :model do
  let(:user) { User.create!(email: "s@example.com") }
  subject { described_class.create!(user: user) }

  it "belongs to user" do
    assoc = described_class.reflect_on_association(:user)
    expect(assoc.macro).to eq(:belongs_to)
  end

  it "sets token and token_digest and expires_at on create" do
    expect(subject.token).to be_present
    expect(subject.token_digest).to be_present
    expect(subject.expires_at).to be > Time.current
  end

  describe "#token_matches?" do
    it "returns true for correct token" do
      t = subject.token
      expect(subject.token_matches?(t)).to be true
    end

    it "returns false for incorrect token" do
      expect(subject.token_matches?("wrong")).to be false
    end
  end

  describe "#expired?" do
    it "is false immediately after create" do
      expect(subject.expired?).to be false
    end

    it "is true after expiration" do
      subject.update!(expires_at: 1.hour.ago)
      expect(subject.expired?).to be true
    end
  end

  describe "#remember" do
    it "sets remember_token and remember_digest" do
      expect(subject.remember_digest).to be_nil
      subject.remember
      expect(subject.remember_token).to be_present
      expect(subject.remember_digest).to be_present
    end
  end

  describe "#refresh" do
    it "extends expires_at" do
      old = subject.expires_at
      subject.refresh
      expect(subject.expires_at).to be > old
    end
  end
end
