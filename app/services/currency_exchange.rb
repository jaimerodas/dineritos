class CurrencyExchange
  def self.get_rate_for(currency, date)
    if Rails.env.test?
      return test_exchange_rates(currency, date)
    end

    fetch_rate_from_api(currency, date)
  end

  def self.fetch_rate_from_api(currency, date)
    access_key = Rails.application.credentials[:fixer]
    url = "http://data.fixer.io/api/#{date}?access_key=#{access_key}&symbols=MXN,#{currency}"
    string = Net::HTTP.get(URI(url))
    object = JSON.parse(string)

    raise unless object["success"]

    object["rates"]["MXN"] / object["rates"][currency]
  end

  def self.test_exchange_rates(currency, date)
    # Default exchange rates for tests
    case currency
    when "USD"
      20.0 # 1 USD = 20.0 MXN
    when "EUR"
      22.0 # 1 EUR = 22.0 MXN
    when "GBP"
      25.0 # 1 GBP = 25.0 MXN
    when "JPY"
      0.18 # 1 JPY = 0.18 MXN
    else
      # If currency not defined, use a sensible default
      1.0 # Same as MXN
    end
  end
end
