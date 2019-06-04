json.totals @report.totals do |total|
  json.date total.date
  json.pretty_date pretty_date(total.date)
  json.amount total.amount.to_f
  json.diff total.diff.to_f
end
