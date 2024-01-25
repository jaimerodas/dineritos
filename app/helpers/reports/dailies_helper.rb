module Reports::DailiesHelper
  def dailies_nav
    tag.nav(class: "button-bar chart-toggle dates") do
      concat(link_to(
        "« #{(@report.date - 1.day)}",
        reports_dailies_path(d: (@report.date - 1.day).to_s),
        class: "btn"
      )) unless @report.date - 1.day == (@report.user.balances.earliest_date)

      concat(link_to(
        "#{(@report.date + 1.day)} »",
        reports_dailies_path(d: (@report.date + 1.day).to_s),
        class: "btn"
      )) if @report.date < Date.current - 1.day

      concat(link_to("Hoy", reports_dailies_path, class: "btn")) if (@report.date < Date.current)
    end
  end
end
