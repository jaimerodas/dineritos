module AccountMovementsHelper
  def prev_month_link
    month_link(@report.prev_month, "Anterior")
  end

  def next_month_link
    month_link(@report.next_month, "Siguiente")
  end

  def month_link(date, title)
    return tag.span(title) unless date
    num_date = l(date, format: :numeric_month)
    link_to(title, account_movements_path(@report.account, month: num_date))
  end

  def account_main_nav(current: "Estadísticas")
    content_tag("ul") {
      concat account_nav_link("Estadísticas", "account_path", current)
      concat account_nav_link("ERs", "account_profit_and_loss_path", current)
      concat account_nav_link("Saldos", "account_movements_path", current)
      concat account_nav_link("Opciones", "edit_account_path", current)
    }
  end

  def account_nav_link(title, path, current)
    content_tag("li") {
      classes = (current == title) ? "active" : ""
      link_to(title, public_send(path, @account), class: classes)
    }
  end
end
