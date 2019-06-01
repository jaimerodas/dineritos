module DatesHelper
  def pretty_date(date)
    format = (date.year == Date.current.year) ? :short : :short_year
    l(date, format: format)
  end
end
