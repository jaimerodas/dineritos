module BalanceFormHelper
  def amount_field(field)
    currency = field.object.account.currency
    input = field.number_field(:amount,
      min: 0,
      pattern: '^\d*(\.\d{0,2})?$',
      step: "0.01",
      value: field.object.original_amount || field.object.amount,
      data: {
        action: "change->form#recalculate keyup->form#recalculate",
        target: "form.balance",
        currency: currency,
      })

    if currency != "MXN"
      input = content_tag("div", class: "input-field") {
        concat input
        concat content_tag("span", currency)
      }
    end

    input
  end
end
