module InvestmentsHelper
  def summary_buttons
    content_tag(
      :div,
      id: "investment-summary-nav",
      class: "chart-toggle",
      data: {target: "investments.summaryButtons"}
    ) do
      concat summary_button(period: "past_year")
      concat summary_button(period: Date.current.year)
      concat summary_button(period: Date.current.year - 1)
    end
  end

  def summary_button(period: "past_year")
    year = period == "past_year" ? "Último Año" : period.to_s
    classes = ["btn"]
    classes << "active" if current_period.to_s == period.to_s

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
