# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoneyHelper, type: :helper do
  describe "#currency" do
    it "renders a dash placeholder for nil" do
      expect(helper.currency(nil)).to eq('<span class="zero">-</span>')
    end

    it "renders a dash placeholder for zero" do
      expect(helper.currency(0)).to eq('<span class="zero">-</span>')
    end

    it "renders an explicit zero when asked" do
      expect(helper.currency(0, zero: true)).to eq('<span class="zero">0.00</span>')
    end

    it "formats a plain amount" do
      expect(helper.currency(1234.5)).to eq("<span>1,234.50</span>")
    end

    it "honours a custom precision" do
      expect(helper.currency(1.23456, decimals: 4)).to eq("<span>1.2346</span>")
    end

    it "prefixes positive diffs with a plus sign" do
      expect(helper.currency(10, diff: true)).to eq('<span class="diff">+10.00</span>')
    end

    it "marks negative diffs" do
      expect(helper.currency(-10, diff: true)).to eq('<span class="diff neg">-10.00</span>')
    end
  end

  describe "#fx" do
    it "renders a dash for a missing rate" do
      expect(helper.fx(nil)).to eq("<span>-</span>")
    end

    it "renders a rate at four decimals" do
      expect(helper.fx(17.1234)).to eq("<span>17.1234</span>")
    end
  end

  describe "#mdiff" do
    it "treats nil as zero" do
      expect(helper.mdiff(nil)).to eq("<span>0.00</span>")
    end

    it "treats an empty string as zero" do
      expect(helper.mdiff("")).to eq("<span>0.00</span>")
    end

    it "colours positive values green and adds a plus sign" do
      html = helper.mdiff(10)
      expect(html).to include("+10.00")
      expect(html).to include("color: #27a717;")
    end

    it "colours negative values red" do
      html = helper.mdiff(-10)
      expect(html).to include("-10.00")
      expect(html).to include("color: #ce3129;")
    end

    it "skips colouring when diff is disabled" do
      expect(helper.mdiff(10, diff: false)).to eq("<span>10.00</span>")
    end

    it "returns unwrapped text in plain mode" do
      expect(helper.mdiff(10, plain: true)).to eq("+10.00")
    end
  end

  describe "#mfx" do
    it "renders four decimals without diff styling" do
      expect(helper.mfx(17.1234)).to eq("<span>17.1234</span>")
    end

    it "supports plain mode" do
      expect(helper.mfx(17.1234, plain: true)).to eq("17.1234")
    end
  end

  describe "#mcur" do
    it "renders two decimals without diff styling" do
      expect(helper.mcur(1234.5)).to eq("<span>1,234.50</span>")
    end

    it "supports plain mode" do
      expect(helper.mcur(1234.5, plain: true)).to eq("1,234.50")
    end
  end
end
