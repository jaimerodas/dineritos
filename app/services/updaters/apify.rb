module Updaters
  class Apify
    def self.current_balance_for(account)
      new(account).call
    end

    def initialize(account)
      @params = account.settings
      @params["inputs"] = inputs
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

    def inputs
      {username: params.fetch("username"), password: params.fetch("password")}
    end

    private

    def last_successful_run_time
      last_successful_run.finished_at
    end

    def last_successful_run
      @last_successful_run ||= ApifyRun.last_successful(params)
    end

    def start_run
      @start_run ||= ApifyRun.new(params)
    end
  end
end
