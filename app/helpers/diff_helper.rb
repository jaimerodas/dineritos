module DiffHelper
  def diff(number)
    text = "-"
    classes = "diff"

    if number
      text = number_to_currency(number, unit: "")
      number.negative? ? classes += " neg" : text = "+#{text}"
    end

    tag.span text, class: classes
  end
end
