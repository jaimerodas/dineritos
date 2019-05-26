class CalculateTotal
  def self.from(balance_date)
    total = balance_date
      .balances
      .group(:balance_date_id)
      .select("SUM(amount_cents) as total")
      .order(nil)
      .first.total

    balance_total = Total.new(
      balance_date: balance_date,
      amount_cents: total
    )

    puts balance_total.inspect

    balance_total.save
  end
end
