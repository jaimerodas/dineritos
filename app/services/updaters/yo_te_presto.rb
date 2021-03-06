class Updaters::YoTePresto
  def self.current_balance_for(account)
    new(account).run
  end

  def initialize(account)
    @username = account.settings.fetch("username")
    @password = account.settings.fetch("password")
  end

  attr_reader :username, :password

  def run
    BigDecimal(raw_account_value)
  end

  private

  def cookies
    @cookies ||= HTTParty.post("https://www.yotepresto.com/sign_in", {
      body: {"sessions[email]" => username, "sessions[password]" => password}
    }).headers["set-cookie"]
      .split(";").map(&:strip)
      .map { |s| s.start_with?("expires") ? s[39..-1] : s }
      .filter { |s| s.start_with? "ytp" }
      .map { |s| s.split("=") }
      .to_h
  end

  def raw_account_value
    HTTParty.get("https://api.yotepresto.com/v1/investor/account_statements", headers: {
      "uid" => username,
      "token-type" => "Bearer",
      "access-token" => cookies.fetch("ytp_access_token"),
      "expiry" => cookies.fetch("ytp_expiry"),
      "client" => cookies.fetch("ytp_client"),
      "Origin" => "https://investor.yotepresto.com"
    }).parsed_response.fetch("valor_cuenta")
  end
end
