module CurrencyConversion
  extend ActiveSupport::Concern

  private

  def cents_to_decimal(amount_in_cents)
    return 0.0 unless amount_in_cents
    BigDecimal(amount_in_cents) / 100.0
  end

  def decimal_to_cents(decimal_amount)
    return 0 unless decimal_amount
    (BigDecimal(decimal_amount) * 100).to_i
  end

  def ensure_numeric(value, default: 0)
    return default unless value
    BigDecimal(value.to_s)
  rescue ArgumentError, TypeError
    default
  end

  def normalize_currency(currency, account_currency)
    return account_currency if currency.blank? || currency == "default"
    currency.to_s.upcase
  end

  # SQL helper for decimal conversion in queries
  def decimalized(sql_expression, alias_name = nil)
    alias_clause = alias_name ? " AS #{alias_name}" : ""
    "(#{sql_expression})::decimal / 100.0#{alias_clause}"
  end
end
