module Updaters
  class ApifyRun
    BASE_URL = "https://api.apify.com/v2"

    def self.last_successful(params, http_handler: HTTParty)
      new(params, last: true, http_handler: http_handler)
    end

    def initialize(params, last: false, http_handler: HTTParty)
      @params = params
      @last = last
      @http_handler = http_handler

      response = if last
        @http_handler.get(initial_url)
      else
        @http_handler.post(initial_url, body: @params.fetch("inputs").to_json, headers: headers)
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
      value = @http_handler.get(url)&.first&.fetch("value")
      BigDecimal(value.tr("^0-9.", "")).round(2)
    end

    def refresh!
      url = to_url("/actor-runs/#{data.fetch("id")}")
      @data = @http_handler.get(url).fetch("data")
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
