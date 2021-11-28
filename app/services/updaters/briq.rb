class Updaters::Briq < BaseScraper
  private

  def login_url
    "https://www.briq.mx/users/sign_in"
  end

  def login
    browser.text_field(id: "user_email").set(username)
    browser.text_field(id: "user_password").set(password)
    browser.form(action: "/users/sign_in?next=2FA").submit
  end

  def raw_value
    browser.div(id: "global-portfolio").children[4].children[1].text
  end
end
