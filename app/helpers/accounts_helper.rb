module AccountsHelper
  def period_buttons
    content_tag(:div, class: "button-bar chart-toggle") do
      concat period_button("1W", "past_week")
      concat period_button("1M", "past_month")
      concat period_button("1Y", "past_year")
      concat period_button("YTD", "year_to_date")
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

  def should_be_shown?(account)
    account.final_balance != 0 ||
      account.total_earnings != 0 ||
      account.total_transferred != 0
  end

  def account_currency_toggle
    return if @report.account.currency == "MXN"
    default_currency = params[:currency].blank? || params[:currency] == "default"
    currency = default_currency ? "mxn" : "default"
    currency_text = default_currency ? "MXN" : @report.account.currency
    current_currency_text = default_currency ? @report.account.currency : "MXN"
    content_tag(:section) do
      concat "Datos en #{current_currency_text}. "
      concat link_to("Ver en #{currency_text}", account_statistics_path(@report.account, currency: currency))
    end
  end
end
