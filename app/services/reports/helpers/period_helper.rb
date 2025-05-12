module Reports
  module Helpers
    module PeriodHelper
      attr_reader :user, :period

      def initialize(user, period_string)
        @user = user
        @period = calculate_period(period_string, earliest_date: earliest_date)
      end

      def earliest_date
        @earliest_date ||= user.balances.earliest_date
      end

      def latest_date
        @latest_date ||= user.balances.latest_date
      end

      private

      # Calculate a date range from period string
      # @param period [String, Integer] Period identifier ("past_year", "all", numeric year, etc.)
      # @param reference_date [Date] The reference date (default: Date.current)
      # @param earliest_date [Date, nil] The earliest possible date (for "all" period)
      # @return [Range] Date range for the specified period
      def calculate_period(period, reference_date: Date.current, earliest_date: nil)
        case period.to_s
        when "past_year"
          1.year.ago(reference_date)..reference_date
        when "past_month"
          1.months.ago(reference_date)..reference_date
        when "past_week"
          1.week.ago(reference_date)..reference_date
        when "year_to_date"
          reference_date.beginning_of_year..reference_date
        when "all"
          earliest_date = fetch_earliest_date if earliest_date.nil? && respond_to?(:fetch_earliest_date)
          raise ArgumentError, "Earliest date required for 'all' period" unless earliest_date
          earliest_date..reference_date
        else
          # Handle numeric year (as string or integer)
          year = period.to_i
          raise ArgumentError, "Invalid period: #{period}" if year.zero?
          Date.new(year)...Date.new(year + 1)
        end
      end
    end
  end
end
