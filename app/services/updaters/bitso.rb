class Updaters::Bitso
  BASE_URL = "https://api.bitso.com"

  def self.current_balance_for(account, http_client: HTTParty)
    new(account, http_client: http_client).run
  end

  def initialize(account, http_client: HTTParty)
    @key = account.settings["bitso_key"]
    @secret = account.settings["bitso_secret"]
    @http_client = http_client
  end

  attr_reader :key, :secret, :http_client

  def run
    calculate_total_from(balances)
  end

  private

  def calculate_total_from(array)
    array.sum do |balance|
      next balance[:amount] if balance[:currency] == "mxn"
      exchange_rate = fetch_exchange_rate(balance[:currency])
      (balance[:amount] * BigDecimal(exchange_rate)).round(2)
    end
  end

  def balances
    response = fetch_balances_from_api
    parse_balances_response(response)
  end

  def fetch_balances_from_api
    nonce = generate_nonce
    path = "/v3/balance/"
    signature = signature(nonce, path)

    http_client.get(BASE_URL + path, headers: {
      "Authorization" => auth_header(nonce, signature)
    })
  end

  def parse_balances_response(response)
    response.dig("payload", "balances").map { |result|
      amount = BigDecimal(result["total"])
      next unless amount > 0
      {amount: amount, currency: result["currency"]}
    }.compact
  end

  def fetch_exchange_rate(currency)
    response = http_client.get(BASE_URL + "/v3/ticker/?book=#{currency}_mxn")
    response.dig("payload", "vwap")
  end

  def generate_nonce
    Time.current.to_i.to_s
  end

  def auth_header(nonce, signature)
    "Bitso #{key}:#{nonce}:#{signature}"
  end

  def signature(nonce, path, payload = "")
    http_method = "GET"
    message = nonce + http_method + path + payload
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, message)
  end
end
