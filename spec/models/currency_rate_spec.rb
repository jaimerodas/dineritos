require "rails_helper"

RSpec.describe CurrencyRate, type: :model do
  # Stub external service
  before do
    allow(CurrencyExchange).to receive(:get_rate_for).with("EUR", Date.new(2021, 1, 1)).and_return(1.2345)
  end

  it "calculates rate_subcents on create" do
    cr = CurrencyRate.create!(currency: "EUR", date: Date.new(2021, 1, 1))
    expect(cr.rate_subcents).to eq((1.2345 * 1_000_000).to_i)
  end

  describe "#rate" do
    it "returns rate as float" do
      cr = CurrencyRate.new(rate_subcents: 987654)
      expect(cr.rate).to eq(987_654 / 1_000_000.0)
    end
  end
end
