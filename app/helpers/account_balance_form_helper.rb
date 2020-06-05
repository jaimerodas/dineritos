module AccountBalanceFormHelper
  def amount_field_for(form)
    field = @balance.foreign_currency? ? :original_amount : :amount

    content_tag("div", class: "field") {
      concat form.label(field)
      concat form.text_field(
        field,
        pattern: '^\-?\d*(\.\d{1,2})?$',
        class: "amount",
        data: {
          target: "edit-balance.amount",
          action: "change->edit-balance#updateResults"
        }
      )
    }
  end
end
