module BalanceFormHelper
  def amount_field(field)
    account = field.object.account
    currency = account.currency
    input = field.number_field(:amount,
      min: 0,
      pattern: '^\d*(\.\d{1,2})?$',
      step: "0.01",
      value: field.object.original_amount || field.object.amount,
      data: {
        action: "change->form#recalculate keyup->form#recalculate",
        target: "form.balance",
        updateable: account.updateable?,
        account: account.id,
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
