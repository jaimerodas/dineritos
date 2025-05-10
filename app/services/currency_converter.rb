# frozen_string_literal: true

class CurrencyConverter
  # Convert a Balance to MXN
  # @param balance [Balance] The balance to convert
  # @return [Balance] The converted MXN balance (existing or newly created)
  def self.to_mxn(balance)
    return balance if balance.currency == "MXN"

    mxn_balance = Balance.find_or_initialize_by(
      account: balance.account,
      date: balance.date,
      currency: "MXN"
    )

    mxn_balance.update(
      validated: balance.validated,
      amount_cents: convert_amount(balance.amount_cents, balance),
      transfers_cents: convert_amount(balance.transfers_cents, balance)
    )

    mxn_balance
  end

  # Convert an amount from a foreign currency to MXN
  # @param amount_cents [Integer] The amount in cents to convert
  # @param balance [Balance] The balance with date and currency info
  # @return [Integer] The amount in MXN cents
  def self.convert_amount(amount_cents, balance)
    (amount_cents * exchange_rate_for(balance)).to_i
  end

  # Get the exchange rate for a balance
  # @param balance [Balance] The balance with date and currency info
  # @return [Float] The exchange rate to MXN
  def self.exchange_rate_for(balance)
    return 1.0 unless balance.foreign_currency?

    rate = CurrencyRate.find_or_create_by(
      date: balance.date,
      currency: balance.currency
    )

    rate.rate_subcents / 1_000_000.0
  end

  # Convert multiple balances to MXN
  # @param balances [Array<Balance>] The balances to convert
  # @return [Array<Balance>] The converted MXN balances
  def self.all_to_mxn(balances)
    balances.map { |balance| to_mxn(balance) }
  end
end
