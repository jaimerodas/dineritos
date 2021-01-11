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
    BigDecimal(invested_funds.to_s) + BigDecimal(available_funds.to_s)
  end

  private

  def token
    @token ||= HTTParty.post(
      "#{BASE_URL}/v1/auth/loginViaApp",
      body: {email: username, password: password}.to_json,
      headers: {"Content-Type" => "application/json"}
    ).parsed_response.fetch("access_token")
  end

  def auth_headers
    @auth_headers ||= {"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"}
  end

  def investor_id
    @investor_id ||= HTTParty.get(
      "#{BASE_URL}/v1/users/getRgUserInfo",
      headers: auth_headers
    ).parsed_response.fetch("investor_id")
  end

  def invested_funds
    HTTParty.get(
      "#{BASE_URL}/v2/investor/#{investor_id}/getLevelData",
      headers: auth_headers
    ).parsed_response.fetch("invested")
  end

  def available_funds
    HTTParty.get(
      "#{BASE_URL}/v2/investor/#{investor_id}/getGeneralData",
      headers: auth_headers
    ).parsed_response.fetch("balance")
  end
end
