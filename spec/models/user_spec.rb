require "rails_helper"

RSpec.describe User, type: :model do
  describe "email normalization" do
    it "downcases email before create" do
      user = User.create!(email: "Foo@ExamPle.Com")
      expect(user.email).to eq("foo@example.com")
    end
  end

  describe "uid generation" do
    it "assigns uid on initialize if blank" do
      user = User.new(email: "x@x.com")
      expect(user.uid).to be_present
    end
  end

  it "has many passkeys" do
    assoc = described_class.reflect_on_association(:passkeys)
    expect(assoc.macro).to eq(:has_many)
  end

  it "has many sessions" do
    assoc = described_class.reflect_on_association(:sessions)
    expect(assoc.macro).to eq(:has_many)
  end
end
