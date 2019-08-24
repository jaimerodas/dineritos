module MoneyHelper
  def diff(number)
    classes = "diff"
    return tag.span("-", class: classes) unless number

    text = currency(number)

    if number.zero? then classes += " zero"
    elsif number.negative? then classes += " neg"
    else text = "+#{text}"
    end

    tag.span text, class: classes
  end

  def currency(number)
    number_to_currency(number, unit: "")
  end
end
