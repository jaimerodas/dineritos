class CurrencyRate < ApplicationRecord
  belongs_to :balance_date

  before_create :get_rates

  private

  def get_rates
    self.rate_subcents = (CurrencyExchange.get_rate_for(currency, balance_date.date) * 1000000).to_i
  end

  def rate
    self.rate_subcents / 1000000.0
  end
end
