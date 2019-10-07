# First we need some accounts:
accounts = Account.create([
  {name: "BBVA"}, {name: "BBVA Dólares", currency: "USD"},
])

# Then we need some dates
dates = BalanceDate.create([
  {date: 8.weeks.ago}, {date: 6.weeks.ago},
  {date: 4.weeks.ago}, {date: 2.weeks.ago},
  {date: Date.current},
])

# Finally we create some balances and totals
dates.each do |date|
  accounts.each do |account|
    date.balances.create(account: account, amount: rand(1000..10000))
  end
  CalculateTotal.from(date)
end
