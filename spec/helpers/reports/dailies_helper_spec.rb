# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::DailiesHelper, type: :helper do
  let(:today) { Date.new(2024, 6, 15) }

  def stub_report(date:, earliest_date: Date.new(2024, 1, 1), latest_date: today)
    helper.instance_variable_set(
      :@report,
      double("Report", date: date, earliest_date: earliest_date, latest_date: latest_date)
    )
  end

  around { |example| travel_to(today) { example.run } }

  describe "#dailies_nav" do
    it "links to both neighbours for a day in the middle of the range" do
      stub_report(date: Date.new(2024, 3, 10))
      html = helper.dailies_nav
      expect(html).to include("« 2024-03-09")
      expect(html).to include("2024-03-11 »")
    end

    it "omits the previous link at the start of the range" do
      stub_report(date: Date.new(2024, 1, 2), earliest_date: Date.new(2024, 1, 1))
      html = helper.dailies_nav
      expect(html).not_to include("«")
      expect(html).to include("2024-01-03 »")
    end

    it "omits the next link on the latest date" do
      stub_report(date: today, latest_date: today)
      html = helper.dailies_nav
      expect(html).to include("« 2024-06-14")
      expect(html).not_to include("»")
    end

    it "omits the next link when data stops before today" do
      stub_report(date: Date.new(2024, 5, 20), latest_date: Date.new(2024, 5, 20))
      expect(helper.dailies_nav).not_to include("»")
    end

    it "offers a shortcut to today when viewing an older day with fresh data" do
      stub_report(date: Date.new(2024, 3, 10), latest_date: today)
      expect(helper.dailies_nav).to include("Hoy")
    end

    it "hides the shortcut when already on the latest day" do
      stub_report(date: today, latest_date: today)
      expect(helper.dailies_nav).not_to include("Hoy")
    end

    it "hides the shortcut when the data is stale" do
      stub_report(date: Date.new(2024, 3, 10), latest_date: Date.new(2024, 5, 1))
      expect(helper.dailies_nav).not_to include("Hoy")
    end
  end
end
