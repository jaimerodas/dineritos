module MoneyHelper
  def currency(number, diff: false)
    return tag.span("-", class: "zero") if !number || number.zero?
    text = number_to_currency(number, unit: "")

    return tag.span(text) unless diff
    number.negative? ? tag.span(text, class: "diff neg") : tag.span("+#{text}", class: "diff")
  end
end
