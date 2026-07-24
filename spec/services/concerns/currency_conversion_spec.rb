# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrencyConversion do
  let(:subject_class) do
    Class.new do
      include CurrencyConversion

      def to_decimal(cents) = cents_to_decimal(cents)

      def to_sql(expression, alias_name) = decimalized(expression, alias_name)
    end
  end

  subject(:converter) { subject_class.new }

  describe "#cents_to_decimal" do
    it "converts cents into a decimal amount" do
      expect(converter.to_decimal(105_00)).to eq(105.0)
    end

    it "keeps sub-unit precision" do
      expect(converter.to_decimal(1_234)).to eq(12.34)
    end

    it "handles negative amounts" do
      expect(converter.to_decimal(-500)).to eq(-5.0)
    end

    it "returns 0.0 when the amount is nil" do
      expect(converter.to_decimal(nil)).to eq(0.0)
    end
  end

  describe "#decimalized" do
    it "builds an aliased decimal cast for a column" do
      expect(converter.to_sql("initial_balance", "starting_balance"))
        .to eq("(initial_balance)::decimal / 100.0 AS starting_balance")
    end

    it "wraps compound expressions so the cast applies to the whole result" do
      expect(converter.to_sql("SUM(diff_cents) - initial_diff", "earnings"))
        .to eq("(SUM(diff_cents) - initial_diff)::decimal / 100.0 AS earnings")
    end
  end
end
