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
    browser.dt(text: /Valor de la cuenta/).following_sibling.child.text
  end
end
