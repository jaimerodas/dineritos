module MoneyHelper
  def currency(number, diff: false, zero: false, decimals: 2)
    return tag.span(zero ? "0.00" : "-", class: "zero") if !number || number.zero?
    text = number_to_currency(number, unit: "", precision: decimals)

    return tag.span(text) unless diff
    number.negative? ? tag.span(text, class: "diff neg") : tag.span("+#{text}", class: "diff")
  end

  def fx(number)
    return tag.span("-") if !number
    tag.span(number_to_currency(number, precision: 4, unit: ""))
  end

  def mdiff(number, diff: true, decimals: 2, plain: false)
    number = 0.0 if !number || number == ""
    text = number_to_currency(number, unit: "", precision: decimals)
    text = "+" + text if diff && number > 0
    return text if plain
    return tag.span(text) if number.zero? || !diff
    tag.span(text, style: number.positive? ? "color: #27a717;" : "color: #ce3129;")
  end

  def mfx(number, plain: false)
    mdiff(number, diff: false, decimals: 4, plain: plain)
  end

  def mcur(number, plain: false)
    mdiff(number, diff: false, plain: plain)
  end
end
