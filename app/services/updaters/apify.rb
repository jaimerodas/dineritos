class Updaters::Apify
  def self.current_balance_for(account)
    new(account).call
  end

  def initialize(account)
    @params = account.settings
  end

  attr_reader :params

  def call
    run = (last_successful_run_time > 22.hours.ago) ? last_successful_run : start_run
    10.times do |i|
      return run.value if run.succeeded?
      sleep 5
      run.refresh!
    end
    raise
  end

  private

  def last_successful_run_time
    last_successful_run.finished_at
  end

  def last_successful_run
    @last_successful_run ||= Run.last_successful(params)
  end

  def start_run
    @start_run ||= Run.new(params)
  end

  class Run
    BASE_URL = "https://api.apify.com/v2"

    def self.last_successful(params)
      new(params, last: true)
    end

    def initialize(params, last: false)
      @params = OpenStruct.new(params)
      url = initial_url(last)
      response = if last
        HTTParty.get(url)
      else
        HTTParty.post(url, body: apify_inputs.to_json, headers: headers)
      end
      @data = response.fetch("data")
    end

    attr_reader :data, :params

    def succeeded?
      data["status"] == "SUCCEEDED"
    end

    def finished_at
      data["finishedAt"].to_time
    end

    def value
      url = to_url("/datasets/#{data["defaultDatasetId"]}/items?")
      value = HTTParty.get(url)&.first&.fetch("value")
      BigDecimal(value.tr("^0-9.", "")).round(2)
    end

    def refresh!
      url = to_url("/actor-runs/#{data.fetch("id")}?")
      @data = HTTParty.get(url).fetch("data")
    end

    private

    def apify_inputs
      {username: @params.username, password: @params.password}
    end

    def headers
      {"Content-Type" => "application/json"}
    end

    def initial_url(last)
      url = "/acts/#{params.actor}/runs"
      url += last ? "/last?status=SUCCEEDED&" : "?"
      to_url(url)
    end

    def to_url(str)
      "#{BASE_URL}#{str}token=#{params.token}"
    end
  end
end
