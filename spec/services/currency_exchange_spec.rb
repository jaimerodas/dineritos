# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrencyExchange do
  describe ".get_rate_for" do
    context "in test environment" do
      it "returns hardcoded exchange rates for USD" do
        rate = described_class.get_rate_for("USD", Date.current)
        expect(rate).to eq(20.0)
      end

      it "returns hardcoded exchange rates for EUR" do
        rate = described_class.get_rate_for("EUR", Date.current)
        expect(rate).to eq(22.0)
      end

      it "returns hardcoded exchange rates for GBP" do
        rate = described_class.get_rate_for("GBP", Date.current)
        expect(rate).to eq(25.0)
      end

      it "returns hardcoded exchange rates for JPY" do
        rate = described_class.get_rate_for("JPY", Date.current)
        expect(rate).to eq(0.18)
      end

      it "returns 1.0 for unspecified currencies" do
        rate = described_class.get_rate_for("CAD", Date.current)
        expect(rate).to eq(1.0)
      end

      it "ignores the date parameter in test environment" do
        rate1 = described_class.get_rate_for("USD", Date.current)
        rate2 = described_class.get_rate_for("USD", Date.current - 1.year)
        expect(rate1).to eq(rate2)
      end
    end

    context "in development and production environments" do
      it "calls fetch_rate_from_api in development" do
        allow(Rails.env).to receive(:test?).and_return(false)
        expect(described_class).to receive(:fetch_rate_from_api).with("USD", Date.current)
        described_class.get_rate_for("USD", Date.current)
      end
    end
  end
end
