class Updaters::Afluenta < Updaters::Apify
  private

  def apify_inputs
    {username: @params.username, password: @params.password, otp_secret: @params.secret}
  end
end
