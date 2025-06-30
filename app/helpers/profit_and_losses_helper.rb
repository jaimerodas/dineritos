module ProfitAndLossesHelper
  def profit_and_loss_period_buttons
    return unless show_period_buttons?

    content_tag(
      :div,
      id: "profit-and-loss-nav",
      class: "chart-toggle"
    ) do
      concat pnl_period_button(period: "past_year")

      if total_button_count <= 4
        # Show all years individually
        Date.current.year.downto(@report.earliest_year).each do |year|
          concat pnl_period_button(period: year)
        end
      else
        # Show current year with nav buttons
        current_year = /^\d{4}$/.match?(current_period.to_s) ? current_period.to_i : Date.current.year

        # Previous year button
        if current_year > @report.earliest_year
          concat nav_button(current_year - 1, "&laquo;")
        end

        # Current year
        concat pnl_period_button(period: current_year)

        # Next year button
        if current_year < Date.current.year
          concat nav_button(current_year + 1, "&raquo;")
        end
      end

      concat pnl_period_button(period: "all")
    end
  end

  def pnl_period_button(period: "past_year")
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
      account_profit_and_loss_path(@report.account, period: period),
      class: classes.join(" ")
    )
  end

  def current_period
    params[:period].blank? ? "past_year" : params[:period]
  end

  def nav_button(year, symbol)
    link_to(
      symbol.html_safe,
      account_profit_and_loss_path(@report.account, period: year),
      class: "btn"
    )
  end

  private

  def show_period_buttons?
    @report.earliest_year < Date.current.year
  end

  def total_button_count
    # 1Y + years + ALL
    2 + (Date.current.year - @report.earliest_year + 1)
  end
end
