module AccountMovementsHelper
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

  def account_nav_link(title, path, current)
    content_tag("li", "data-account-header-target": "link") {
      classes = (current == title) ? "active" : ""
      link_to(title, public_send(path, @account), class: classes)
    }
  end
end
