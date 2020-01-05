module BalanceFormHelper
  def amount_field(container, account)
    field_name = account.currency != "MXN" ? :original_amount : :amount

    input = container.number_field(field_name,
      min: 0,
      pattern: '^\d*(\.\d{1,2})?$',
      step: "0.01",
      value: account.original_amount || account.amount || 0.0,
      data: {
        action: "change->form#recalculate keyup->form#recalculate",
        target: "form.balance",
        account: account.id,
        currency: account.currency,
      })

    if account.currency != "MXN"
      input = content_tag("div", class: "input-field") {
        concat input
        concat content_tag("span", account.currency)
      }
    end

    content_tag(:div, class: "field") {
      concat container.label(field_name, account.name)
      concat input
      if account.date
        concat content_tag(:p, "Última actualización: #{account.date}", class: "form-help")
      end
    }
  end

  def self_updating_notice
    return if @data.non_editable_accounts.empty?

    messages = {
      true => ["Las cuentas", "actualizan solas"],
      false => ["La cuenta", "actualiza sola"],
    }

    plural = @data.non_editable_accounts.count > 1
    names = @data.non_editable_accounts.join(", ")

    content_tag("p") {
      concat messages[plural][0] + " "
      concat content_tag("b", names)
      concat " se " + messages[plural][1] + "."
    }
  end
end
