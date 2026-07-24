# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::StatementsHelper, type: :helper do
  let(:period) { [Date.new(2024, 3, 1), Date.new(2024, 3, 31)] }
  let(:statement) { double("Statement", earliest_date: Date.new(2020, 1, 1), period: period) }

  before do
    helper.instance_variable_set(:@statement, statement)
    allow(helper).to receive(:params).and_return({})
  end

  describe "#statement_period_buttons" do
    it "renders the relative period buttons" do
      travel_to Date.new(2024, 6, 15) do
        html = helper.statement_period_buttons
        expect(html).to include("chart-toggle")
        expect(html).to include(">1W<", ">1M<", ">1Y<")
      end
    end

    it "marks the active period" do
      travel_to Date.new(2024, 6, 15) do
        allow(helper).to receive(:params).and_return({period: "past_month"})
        expect(helper.statement_period_buttons).to include('class="btn active"')
      end
    end
  end

  describe "year navigation" do
    context "when the statement only spans the current year" do
      let(:statement) { double("Statement", earliest_date: Date.new(2024, 1, 1), period: period) }

      it "omits year buttons entirely" do
        travel_to Date.new(2024, 6, 15) do
          html = helper.statement_period_buttons
          expect(html).not_to include("«")
          expect(html).not_to include("»")
          expect(html).not_to include(">2024<")
        end
      end
    end

    context "when viewing the current year" do
      it "offers a step back but not forward" do
        travel_to Date.new(2024, 6, 15) do
          html = helper.statement_period_buttons
          expect(html).to include(">2024<")
          expect(html).to include("»")     # older year available
          expect(html).not_to include("«") # nothing newer than the current year
        end
      end
    end

    context "when viewing a middle year" do
      it "offers steps in both directions" do
        travel_to Date.new(2024, 6, 15) do
          allow(helper).to receive(:params).and_return({period: "2022"})
          html = helper.statement_period_buttons
          expect(html).to include(">2022<")
          expect(html).to include("«")
          expect(html).to include("»")
        end
      end
    end

    context "when viewing the earliest year" do
      it "offers a step forward but not further back" do
        travel_to Date.new(2024, 6, 15) do
          allow(helper).to receive(:params).and_return({period: "2020"})
          html = helper.statement_period_buttons
          expect(html).to include(">2020<")
          expect(html).to include("«")
          expect(html).not_to include("»")
        end
      end
    end

    context "when a relative period is selected" do
      it "falls back to the current year for navigation" do
        travel_to Date.new(2024, 6, 15) do
          allow(helper).to receive(:params).and_return({period: "past_week"})
          expect(helper.statement_period_buttons).to include(">2024<")
        end
      end
    end
  end

  describe "#statement_account_link" do
    let(:line) { double("Line", id: 3, name: "Bitso") }

    it "links to undated movements for a weekly period" do
      allow(helper).to receive(:params).and_return({period: "past_week"})
      html = helper.statement_account_link(line)
      expect(html).to include("Bitso")
      expect(html).to include(account_movements_path(3))
      expect(html).not_to include("month=")
    end

    it "links to the statement month for a monthly period" do
      allow(helper).to receive(:params).and_return({period: "past_month"})
      expect(helper.statement_account_link(line)).to include("month=2024-03")
    end

    it "links to the account period page otherwise" do
      allow(helper).to receive(:params).and_return({period: "2023"})
      html = helper.statement_account_link(line)
      expect(html).to include(account_path(3, period: "2023"))
    end
  end
end
