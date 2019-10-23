class BriqService
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
    browser.goto "https://www.briq.mx/users/sign_in"
    login
    value = browser.div(id: "global-portfolio").children[3].children[1].text
    BigDecimal(value.tr("^0-9.", "")).round(2)
  ensure
    browser.close
  end

  def login
    browser.text_field(id: "user_email").set(username)
    browser.text_field(id: "user_password").set(password)
    browser.form(action: "/users/sign_in").submit
  end
end
