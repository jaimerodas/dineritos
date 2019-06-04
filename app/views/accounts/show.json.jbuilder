account = @report.account(params[:id]).first
json.name account.name

json.balances @report.account(params[:id]) do |balance|
  json.date balance.date
  json.pretty_date pretty_date(balance.date)
  json.amount balance.amount.to_f
  json.diff balance.diff.to_f
end
