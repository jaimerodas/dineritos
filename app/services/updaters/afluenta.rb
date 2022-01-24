class Updaters::Afluenta < BaseScraper
  private

  def login_url
    "https://www.afluenta.mx/mi_afluenta/ingresar"
  end

  def login
    form = browser.form(id: "session_bar_form_login")
    form.text_field(id: "login_username").set(username)
    form.text_field(id: "login_password").set(password)
    form.submit

    totp = ROTP::TOTP.new(settings.fetch("secret"), issuer: settings.fetch("issuer"))
    browser.text_field(data_target_function: "two_factor_verified").set(totp.now)
    browser.send_keys :enter
    sleep(5)
  end

  def raw_value
    browser.goto "https://www.afluenta.mx/render/controlpanel/lender_account_summary"
    browser.div(id: "content").child.child.child.children[1].child.child.children[1].text
  end
end
