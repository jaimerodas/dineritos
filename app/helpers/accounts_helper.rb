module AccountsHelper
  def period_buttons
    content_tag(:div, class: "button-bar chart-toggle") do
      concat period_button("1W", "past_week")
      concat period_button("1M", "past_month")
      concat period_button("1Y", "past_year")
    end
  end

  def period_button(text, period)
    current_period = params[:period] || AccountsController::DEFAULT_PERIOD
    classes = ["btn"]
    classes << "active" if current_period == period
    link_to(
      text,
      accounts_path(period: period),
      class: classes.join(" ")
    )
  end
end
