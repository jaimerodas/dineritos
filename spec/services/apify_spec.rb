require "./app/services/updaters/apify"
require "ostruct"
require "json"

RSpec.describe Updaters::Apify do
  context "balance from today with everything changed" do
    let(:run) { Updaters::Apify::Run.new({username: "test", password: "test", actor: "test"}) }

    it "should send email" do
      expect(run.send(:initial_url, true)).to eq "https://api.apify.com/v2/acts/test/runs/last?status=SUCCEEDED&token="
    end

    it "should send email" do
      expect(run.send(:to_url, "/abc")).to eq "https://api.apify.com/v2/abc?token="
    end
  end

  class HTTParty
    def self.get(*)
      new(*)
    end

    def self.post(*)
      new(*)
    end

    def initialize(*params)
    end

    def fetch(key)
      {}
    end
  end
end
