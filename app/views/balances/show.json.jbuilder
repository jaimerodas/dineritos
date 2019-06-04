json.date @report.date
json.pretty_date pretty_date(@report.date)
json.total @report.total.amount.to_f
json.diff @report.total.diff.to_f

json.accounts @report.accounts do |account|
  json.id account.aid
  json.name account.name
  json.amount account.amount.to_f
  json.diff account.diff.to_f
end
