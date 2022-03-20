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
    {"Content-Type" => "application/json", "Host" => "api.redgirasol.com", "Origin" => "https://app.redgirasol.com"}
  end

  def token_response
    @token_response ||= HTTParty.post(
      "#{BASE_URL}/v1/auth/loginViaApp",
      body: {email: username, password: password}.to_json,
      headers: base_headers.merge(
        "Referer" => "https://app.redgirasol.com/login",
        "Authorization" => "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI5IiwianRpIjoiMjdjYTllZWNkZDFiNTI2ZmUxY2EzMmEwMDNlNDg5MTY3NzFmNDM0MWM3ZTViMTNkMGUxMGRkYzUyMzgxN2YzNjcwZTRlZTM2ODNlNGU2OTkiLCJpYXQiOjE2MTkxODc4MjUuMDE0OTM4LCJuYmYiOjE2MTkxODc4MjUuMDE0OTQ1LCJleHAiOjE2NTA3MjM4MjQuOTk5Mjk0LCJzdWIiOiIxIiwic2NvcGVzIjpbImxvZ2luLXVzZXIiLCJsb2dpbi1wYXNzd29yZCJdfQ.kcF4BmZdd2szU4VnpJTa4jp6avbOynr3AqrYcyRnIyf4hWNm6XV_DDE8sPCMexTnSS0u3jDPHH-QEYmt0T3fcG8EGBjqerXf79Krn-j2FCzA7ugH3U4T5kxQPSX0CBmH2ypXh3iMjbsVQjR8wfVy1YgY1VY3dcpbEIddy_m2Kja4Gx_s4ccXkpxtzGuRsOf9I6RG-iD1Q1NbX2zPZ_ybg82Bxfqweyp0EQbsU-8OmBx2R6uoHLdUod4Fw7UO6bxnA3nNLFym_0cqIk215w72drh6a2qHySjbldmbdbrK2jv1-hWjciSy_-s6M8VXWYKGajv5Z-IygtOkOgEOfwbIu-YdZfScULVRQMFK16O6wF_RbDFUQFJxaqqK6d8STCLbtyUEYxRSqnq3_PQVhiD2aFfazo2-6L37Kin8NsPRCKEdxNUe_uo6vNFvDfQbWO37iirLiNIdQR9-_VBgnzGZ4gqUTttt_xkOgxjjZmHYlL7QJynlD4kotT7F8OvuRXfNRsH2rpqKswPScovRQ3rTpqpqaOnPXsQKOE2lWixlWVKVHAT6FSLrWO_F2GIKlelz2f8qtvjuMw8D9mDICgFIGIwUBEl0occ5ZqLPmhGM_VkxmC1Fr510hXCK5dwKnHntKZOizI1W_7oiM2i8B3_lwrmXBy5kqiZ7MpU-V6WvCWI"
      )
    ).parsed_response
  end

  def token
    @token ||= token_response.fetch("access_token")
  rescue NoMethodError
    ErrorsMailer.generic(token_response.to_s, title: "RedGirasol #{Date.current}")
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
