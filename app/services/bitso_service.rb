class BitsoService
  BASE_URL = "https://api.bitso.com"

  def self.current_balance_for(account)
    new(account).run
  end

  def initialize(account)
    @key = account.settings["bitso_key"]
    @secret = account.settings["bitso_secret"]
  end

  attr_reader :key, :secret

  def run
    calculate_total_from(balances)
  end

  private

  def calculate_total_from(array)
    array.sum do |balance|
      next balance[:amount] if balance[:currency] == "mxn"
      exchange_rate = HTTParty.get(BASE_URL + "/v3/ticker/?book=#{balance[:currency]}_mxn")
        .dig("payload", "vwap")
      (balance[:amount] * BigDecimal(exchange_rate)).round(2)
    end
  end

  def balances
    nonce = generate_nonce
    path = "/v3/balance/"
    signature = signature(nonce, path)

    HTTParty.get(BASE_URL + path, headers: {
      "Authorization" => auth_header(nonce, signature),
    }).dig("payload", "balances").map { |result|
      amount = BigDecimal(result["total"])
      next unless amount > 0
      {amount: amount, currency: result["currency"]}
    }.compact
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
