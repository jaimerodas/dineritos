module AccountBalanceFormHelper
  def amount_field_for(form)
    content_tag("div", class: "field") {
      concat form.label(:amount)
      concat form.text_field(
        :amount,
        pattern: '^\-?\d*(\.\d{1,2})?$',
        class: "amount",
        data: {
          "edit-balance-target": "amount",
          action: "change->edit-balance#updateResults"
        }
      )
    }
  end
end
