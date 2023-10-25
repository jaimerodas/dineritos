module InvestmentsHelper
  def summary_buttons
    content_tag(
      :div,
      id: "investment-summary-nav",
      class: "chart-toggle",
      "data-investments-target": "summaryButtons"
    ) do
      concat summary_button(period: "past_year")
      concat summary_button(period: "all")
      concat summary_button(period: Date.current.year)
      concat summary_button(period: Date.current.year - 1)
    end
  end

  def summary_button(period: "past_year")
    year = (period == "past_year") ? "1Y" : period.to_s.upcase
    classes = ["btn"]
    classes << "active" if current_period.to_s == period.to_s
    classes << "year" if period.is_a? Integer

    link_to(
      year,
      root_path(period: period),
      class: classes.join(" "),
      data: {
        action: "click->investments#updateSummary",
        url: "/inversiones/resumen.html?period=#{period}"
      }
    )
  end

  def current_period
    params[:period].blank? ? InvestmentsController::DEFAULT_PERIOD : params[:period]
  end
end
