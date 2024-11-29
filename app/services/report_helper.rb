module ReportHelper
  private

  def cents_to_decimal(amount)
    amount ? amount / 100.0 : 0.0
  end

  def determine_period_range(year, account)
    case year
    when "past_year" then 1.year.ago.beginning_of_month..Date.current
    when "all" then account.balances.earliest_date..Date.current
    else
      year = year.to_i if year.instance_of?(String)
      Date.new(year)...Date.new(year + 1)
    end
  end

  def validate_user_account!(user, account)
    raise ArgumentError, "Unauthorized user for this account" unless account.user == user
  end
end
