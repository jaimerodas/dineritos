module ProfitAndLossesHelper
  def account_period_navigation
    return unless @report.earliest_year < Date.current.year

    content_tag(
      :section,
      id: "profit-and-loss-nav",
      class: "chart-toggle"
    ) do
      concat account_period_link(period: "past_year")

      if (Date.current.year - @report.earliest_year) <= 1
        # Show all years individually
        Date.current.year.downto(@report.earliest_year).each do |year|
          concat account_period_link(period: year)
        end
      else
        # Show current year with nav buttons
        current_year = /^\d{4}$/.match?(current_period.to_s) ? current_period.to_i : Date.current.year

        # Previous year button
        if current_year > @report.earliest_year
          concat nav_button(current_year - 1, "&laquo;")
        end

        # Current year
        concat account_period_link(period: current_year)

        # Next year button
        if current_year < Date.current.year
          concat nav_button(current_year + 1, "&raquo;")
        end
      end

      concat account_period_link(period: "all")
    end
  end

  def account_period_link(period: "past_year")
    text = case period.to_s
    when "past_year"
      "1Y"
    when "all"
      "ALL"
    else
      period.to_s
    end

    classes = ["btn"]
    classes << "active" if current_period.to_s == period.to_s
    classes << "year" if period.is_a? Integer

    link_to(
      text,
      account_path(@report.account, period: period),
      class: classes.join(" ")
    )
  end

  def current_period
    params[:period].blank? ? "past_year" : params[:period]
  end

  def nav_button(year, symbol)
    link_to(
      symbol.html_safe,
      account_path(@report.account, period: year),
      class: "btn"
    )
  end
end
