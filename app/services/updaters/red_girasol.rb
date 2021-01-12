class Updaters::RedGirasol
  BASE_URL = "https://www.redgirasol.com/api"

  def self.current_balance_for(account)
    new(account).run
  end

  def initialize(account)
    @username = account.settings.fetch("username")
    @password = account.settings.fetch("password")
  end

  attr_reader :username, :password

  def run
    invested_funds + available_funds
  end

  private

  def base_headers
    {"Content-Type" => "application/json", "Origin" => "https://app.redgirasol.com"}
  end

  def token
    @token ||= HTTParty.post(
      "#{BASE_URL}/v1/auth/loginViaApp",
      body: {email: username, password: password}.to_json,
      headers: base_headers.merge("Referer" => "https://app.redgirasol.com/login")
    ).parsed_response.fetch("access_token")
  end

  def auth_headers
    @auth_headers ||= base_headers.merge("Authorization" => "Bearer #{token}")
  end

  def api_call(url, param)
    HTTParty.get(BASE_URL + url, headers: auth_headers).parsed_response.fetch(param).to_s
  end

  def investor_id
    @investor_id ||= api_call("/v1/users/getRgUserInfo", "investor_id")
  end

  def invested_funds
    BigDecimal api_call("/v2/investor/#{investor_id}/getLevelData", "invested")
  end

  def available_funds
    BigDecimal api_call("/v2/investor/#{investor_id}/getGeneralData", "balance")
  end
end
