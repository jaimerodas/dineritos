class CalculateTotal
  def self.from(balance_date)
    total = balance_date
      .balances
      .group(:balance_date_id)
      .select("SUM(amount_cents) as total")
      .order(:balance_date_id)
      .first.total

    balance_total = Total.new(
      balance_date: balance_date,
      amount_cents: total
    )

    balance_total.save
  end
end
