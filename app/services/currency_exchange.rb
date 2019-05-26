class CurrencyExchange
  def self.get_rate_for(currency, date)
    access_key = Rails.application.credentials[:fixer]
    url = "http://data.fixer.io/api/#{date}?access_key=#{access_key}&symbols=MXN,#{currency}"
    string = Net::HTTP.get(URI(url))
    object = JSON.parse(string)

    raise unless object["success"]

    object["rates"]["MXN"] / object["rates"][currency]
  end
end
