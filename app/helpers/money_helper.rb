module MoneyHelper
  def currency(number, diff: false, zero: false)
    return tag.span(zero ? "0.00" : "-", class: "zero") if !number || number.zero?
    text = number_to_currency(number, unit: "")

    return tag.span(text) unless diff
    number.negative? ? tag.span(text, class: "diff neg") : tag.span("+#{text}", class: "diff")
  end

  def plainc(number)
    return "0.00" if !number || number.zero?
    number_to_currency(number, unit: "")
  end

  def mailc(number, diff: true)
    return tag.span("0.00") if !number || number.zero?
    text = number_to_currency(number, unit: "")
    return tag.span(text) unless diff
    number.negative? ? tag.span(text, style: "color: #ce3129;") : tag.span("+#{text}", style: "color: #27a717;")
  end
end
