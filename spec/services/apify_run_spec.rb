require "./app/services/updaters/apify_run"
require "ostruct"
require "json"

RSpec.describe Updaters::ApifyRun do
  class FakeHTTParty
    def self.get(url)
      new({url: url})
    end

    def self.post(url, **params)
      new({url: url}.merge(params))
    end

    def initialize(params)
      @data = params
    end

    def fetch(key)
      @data.merge("id" => 1)
    end
  end

  context "new run" do
    let(:run) { described_class.new(params, http_handler: FakeHTTParty) }

    it "went to the right url" do
      expect(run.data.fetch(:url)).to eq "https://api.apify.com/v2/acts/test/runs?token=test"
    end

    it "included headers" do
      expect(run.data.keys).to include :headers
    end

    it "sent the right url when refreshed" do
      run.refresh!
      expect(run.data.fetch(:url)).to eq "https://api.apify.com/v2/actor-runs/1?token=test"
    end
  end

  context "last run" do
    let(:run) { described_class.last_successful(params, http_handler: FakeHTTParty) }

    it "went to the right url" do
      expect(run.data.fetch(:url)).to eq "https://api.apify.com/v2/acts/test/runs/last?status=SUCCEEDED&token=test"
    end

    it "didn't include headers" do
      expect(run.data.keys).not_to include :headers
    end
  end

  def params
    {"actor" => "test", "token" => "test", "inputs" => {}}
  end
end
