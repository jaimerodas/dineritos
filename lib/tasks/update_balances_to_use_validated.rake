desc "Updates balances to use Validated"
task update_balances_to_use_validated: :environment do
  puts "Starting update..."

  # Primero actualicemos los balances que sabemos que fueron validados
  validated_balances = Balance.where("transfers_cents != 0")
    .or(Balance.where("diff_cents != 0"))
    .or(Balance.where("diff_days > 1"))
    .where(validated: false)
  validated_balances_count = validated_balances.count
  validated_balances.update_all(validated: true)

  validated_balances = Balance.where(
    account: Account.updateable, validated: false
  )
  validated_balances_count += validated_balances.count
  validated_balances.update_all(validated: true)

  puts "#{validated_balances_count} validated balances found and updated"

  # Reescribimos los de USD
  usd_balances = Balance.where(currency: "USD", validated: false)
  usd_balances_count = usd_balances.count

  usd_balances.each do |b|
    Balance.find_by(currency: "MXN", date: b.date, account: b.account).update_attribute(:validated, false)
  end

  puts "#{usd_balances_count} USD balances corrected"

  # Recreamos los Balances faltantes a través de diff_days
  created = 0

  Balance.where("diff_days > 1").each do |b|
    previous = b.prev
    date = previous.date + 1.day

    until date == b.date
      Balance.create(
        account: b.account,
        amount_cents: previous.amount_cents,
        date: date,
        transfers_cents: 0,
        currency: b.currency,
        validated: false
      )

      created += 1
      date += 1.day
    end

    b.update_attribute(:diff_days, 1)
  end

  puts "#{created} balances created to fill in gaps"
end
