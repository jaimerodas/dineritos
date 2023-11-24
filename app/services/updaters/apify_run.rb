module Updaters
  class ApifyRun
    BASE_URL = "https://api.apify.com/v2"

    def self.last_successful(params)
      new(params, last: true)
    end

    def initialize(params, last: false)
      @params = params
      @last = last

      response = if last
        HTTParty.get(initial_url)
      else
        HTTParty.post(initial_url, body: @params.fetch("inputs").to_json, headers: headers)
      end
      @data = response.fetch("data")
    end

    attr_reader :data, :params, :last

    def succeeded?
      data.fetch("status", nil) == "SUCCEEDED"
    end

    def finished_at
      data.fetch("finishedAt").to_time
    end

    def value
      url = to_url("/datasets/#{data["defaultDatasetId"]}/items")
      value = HTTParty.get(url)&.first&.fetch("value")
      BigDecimal(value.tr("^0-9.", "")).round(2)
    end

    def refresh!
      url = to_url("/actor-runs/#{data.fetch("id")}")
      @data = HTTParty.get(url).fetch("data")
    end

    private

    def headers
      {"Content-Type" => "application/json"}
    end

    def initial_url
      url = "/acts/#{params.fetch("actor")}/runs"
      last ? to_url(url + "/last", "status=SUCCEEDED") : to_url(url)
    end

    def to_url(path, query = nil)
      query = [query, "token=#{params.fetch("token")}"].compact.join("&")
      "#{BASE_URL}#{path}?#{query}"
    end
  end
end
