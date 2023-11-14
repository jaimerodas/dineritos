class Updaters::Afluenta < Updaters::Apify
  def inputs
    {
      username: params.fetch("username"),
      password: params.fetch("password"),
      otp_secret: params.fetch("secret")
    }
  end
end
