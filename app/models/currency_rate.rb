class CurrencyRate < ApplicationRecord
  belongs_to :balance_date

  before_create :calculate_rate

  private

  def calculate_rate
    self.rate_subcents = (CurrencyExchange.get_rate_for(currency, balance_date.date) * 1000000).to_i
  end

  def rate
    rate_subcents / 1000000.0
  end
end
