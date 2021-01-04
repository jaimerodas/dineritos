module MoneyHelper
  def currency(number, diff: false, zero: false)
    return tag.span(zero ? "0.00" : "-", class: "zero") if !number || number.zero?
    text = number_to_currency(number, unit: "")

    return tag.span(text) unless diff
    number.negative? ? tag.span(text, class: "diff neg") : tag.span("+#{text}", class: "diff")
  end
end
