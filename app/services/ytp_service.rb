class YtpService
  def self.current_balance_for(account)
    new(account).run
  end

  def initialize(account)
    @browser = Watir::Browser.new(:chrome, headless: true)
    @username = account.settings.fetch("username")
    @password = account.settings.fetch("password")
  end

  attr_accessor :browser
  attr_reader :username, :password

  def run
    browser.goto "https://www.yotepresto.com/sesion-inversionistas"
    login
    value = browser.strong(class: "account_value").text
    logout
    BigDecimal(value.tr("^0-9.", "")).round(2)
  ensure
    browser.close
  end

  def login
    browser.text_field(id: "sessions_email").set(username)
    browser.text_field(id: "sessions_password").set(password)
    browser.form(action: "/sign_in").submit
  end

  def logout
    browser.div(class: "flash-notice").click
    sleep(1)
    browser.link(id: "#dLabel").click
    browser.link(href: "/sign_out").click
  end
end
