module MoneyHelper
  def diff(number, unit: "")
    classes = "diff"
    return tag.span("-", class: classes += " zero") if !number || number.zero?

    text = currency(number, unit: unit)

    if number.zero? then classes += " zero"
    elsif number.negative? then classes += " neg"
    else text = "+#{text}"
    end

    tag.span text, class: classes
  end

  def currency(number, unit: "")
    number_to_currency(number, unit: unit)
  end
end
