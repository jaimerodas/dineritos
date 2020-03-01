class Updaters::RedGirasol < BaseScraper
  private

  def login_url
    "https://www.redgirasol.com/login"
  end

  def login
    browser.text_field(class: "form-control", visible: true).set(username)
    browser.button(class: %w[btn btn-md], visible: true).click

    sleep 3

    browser.text_field(class: "form-control", visible: true).set(password)
    browser.button(class: %w[btn btn-md], visible: true).click
  end

  def logout
    browser.goto "https://www.redgirasol.com/logout"
  end

  def raw_value
    browser.goto "https://www.redgirasol.com/inversionistas/mis-inversiones/portafolio"
    browser.div(class: %w[briefcase-total outside]).text
  end
end
