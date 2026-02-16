module Reports::StatementsHelper
  def statement_period_buttons
    content_tag(:div, class: "button-bar chart-toggle") do
      concat statement_period_button("1W", "past_week")
      concat statement_period_button("1M", "past_month")
      concat statement_period_button("1Y", "past_year")
      concat_year_navigation
    end
  end

  def statement_account_link(line)
    period = statement_current_period
    path = if period == "past_week"
      account_movements_path(line.id)
    elsif period == "past_month"
      account_movements_path(line.id, month: @statement.period.last.strftime("%Y-%m"))
    else
      account_path(line.id, period: period)
    end
    link_to line.name, path
  end

  private

  def concat_year_navigation
    earliest_year = @statement.earliest_date.year
    return if earliest_year >= Date.current.year

    current_year = /^\d{4}$/.match?(statement_current_period) ? statement_current_period.to_i : Date.current.year

    if current_year < Date.current.year
      concat statement_period_button("\u00AB", current_year + 1)
    end

    concat statement_period_button(current_year.to_s, current_year)

    if current_year > earliest_year
      concat statement_period_button("\u00BB", current_year - 1)
    end
  end

  def statement_period_button(text, period)
    classes = ["btn"]
    classes << "active" if statement_current_period == period.to_s
    link_to(text, reports_statements_path(period: period), class: classes.join(" "))
  end

  def statement_current_period
    @statement_current_period ||= params[:period].presence || Date.current.year.to_s
  end
end
