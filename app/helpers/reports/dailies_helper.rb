module Reports::DailiesHelper
  def dailies_nav
    tag.nav(class: "button-bar chart-toggle dates") do
      if @report.date > @report.earliest_date + 1.day
        concat(link_to(
          "« #{@report.date - 1.day}",
          reports_dailies_path(d: (@report.date - 1.day).to_s),
          class: "btn"
        ))
      end

      if @report.date < Date.current - 1.day &&
          @report.date < @report.latest_date - 1.day

        concat(link_to(
          "#{@report.date + 1.day} »",
          reports_dailies_path(d: (@report.date + 1.day).to_s),
          class: "btn"
        ))
      end

      concat(link_to("Hoy", reports_dailies_path, class: "btn")) if
        Date.current == @report.latest_date &&
          @report.date < Date.current
    end
  end
end
