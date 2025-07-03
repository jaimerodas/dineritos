module AccountNavigationHelper
  # Period navigation (years/periods for account show pages)

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
          concat nav_button(current_year - 1, "«")
        end

        # Current year
        concat account_period_link(period: current_year)

        # Next year button
        if current_year < Date.current.year
          concat nav_button(current_year + 1, "»")
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
    link_to(symbol, account_path(@report.account, period: year), class: "btn")
  end

  # Month navigation (for account movements pages)

  def account_month_navigation
    return unless @report.prev_month || @report.next_month

    content_tag(:section, class: "chart-toggle") do
      concat prev_month_link if @report.prev_month
      concat next_month_link if @report.next_month
    end
  end

  def prev_month_link
    month_link(@report.prev_month)
  end

  def next_month_link
    month_link(@report.next_month)
  end

  def month_link(date)
    return unless date
    num_date = l(date, format: :numeric_month)
    txt_date = l(date, format: :month).capitalize
    link_to(txt_date, account_movements_path(@report.account, month: num_date), class: "btn")
  end

  # Shared account navigation (for account headers)

  def account_main_nav(current: "Resumen")
    if @account.new_and_empty?
      content_tag("ul", "data-account-header-target": "nav") {
        concat account_nav_link("Resumen", "account_path", current)
        concat account_nav_link("Opciones", "edit_account_path", current)
      }
    else
      existing_account_nav(current: current)
    end
  end

  def existing_account_nav(current: "Resumen")
    content_tag("ul", "data-account-header-target": "nav") {
      concat account_nav_link("Resumen", "account_path", current)
      concat account_nav_link("Detalle", "account_movements_path", current)
      concat account_nav_link("Estadísticas", "account_statistics_path", current)
      concat account_nav_link("Opciones", "edit_account_path", current)
    }
  end

  def account_nav_link(title, path_method, current)
    active_class = (current == title) ? "active" : ""
    content_tag("li", "data-account-header-target": "link") do
      link_to(title, send(path_method, @account || @report.account), class: active_class)
    end
  end
end
