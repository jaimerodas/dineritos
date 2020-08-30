namespace :balances do
  desc "migrates balances to structure with several currencies"
  task create_original_currency: :environment do
    Account.where.not(currency: "MXN").each do |account|
      next if account.balances.where.not(currency: "MXN").count > 0

      account.balances.all.each do |balance|
        exchange_rate = CurrencyRate.find_by(
          date: balance.date,
          currency: account.currency
        ).rate_subcents / 1000000.0

        transfers = (balance.transfers_cents || 0) / exchange_rate

        account.balances.create(
          currency: account.currency,
          date: balance.date,
          amount_cents: balance.original_amount_cents,
          diff_days: balance.diff_days,
          transfers_cents: transfers || nil
        )
      end
    end
  end
end
