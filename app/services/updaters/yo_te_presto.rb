class Updaters::YoTePresto < BaseScraper
  private

  def login_url
    "https://www.yotepresto.com/login"
  end

  def login
    # browser.text_field(id: "email-field").set(username)
    browser.text_field(id: "email-field-clone").set(username)
    sleep(2)
    browser.form(action: "/email_validation").submit

    sleep(5)

    browser.text_field(id: "sessions_password").set(password)
    browser.form(action: "/sign_in").submit

    sleep(15)
  end

  def raw_value
    browser.div(class: "balance__quantity").text
  end

  def logout
    browser.execute_script(
      "document.querySelectorAll('[data-testid=\"header-button\"]:last-child')[0].click()"
    )
    browser.button(class: "end__session").click
  end
end
