module CurrencyConversion
  extend ActiveSupport::Concern

  private

  def cents_to_decimal(amount_in_cents)
    return 0.0 unless amount_in_cents
    BigDecimal(amount_in_cents) / 100.0
  end

  # SQL helper for decimal conversion in queries
  def decimalized(sql_expression, alias_name)
    "(#{sql_expression})::decimal / 100.0 AS #{alias_name}"
  end
end
