class Scrapers::YoTePresto < BaseScraper
  private

  def login_url
    "https://www.yotepresto.com/sesion-inversionistas"
  end

  def login
    browser.text_field(id: "sessions_email").set(username)
    browser.text_field(id: "sessions_password").set(password)
    browser.form(action: "/sign_in").submit
  end

  def raw_value
    browser.strong(class: "account_value").text
  end

  def logout
    browser.div(class: "flash-notice").click
    sleep(1)
    browser.link(id: "#dLabel").click
    browser.link(href: "/sign_out").click
  end
end
