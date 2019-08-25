class CurrencyRate < ApplicationRecord
  before_create :calculate_rate

  def rate
    rate_subcents / 1000000.0
  end

  private

  def calculate_rate
    self.rate_subcents = (CurrencyExchange.get_rate_for(currency, date) * 1000000).to_i
  end
end
