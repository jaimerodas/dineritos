class Updaters::LaTasa < BaseScraper
  private

  def login_url
    "https://panel.latasa.mx/login"
  end

  def login
    form = browser.form(action: "/login")
    form.text_field(name: "email").set(username)
    form.text_field(name: "password").set(password)
    form.submit
  end

  def raw_value
    browser.h2(text: /Valor de la cuenta/).parent.previous_sibling.text
  end
end
