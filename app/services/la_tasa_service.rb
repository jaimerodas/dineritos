class LaTasaService
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
    browser.goto "https://panel.latasa.mx/login"
    login
    value = browser.dt(text: /Valor de la cuenta/).following_sibling.child.text
    BigDecimal(value.tr("^0-9.", "")).round(2)
  ensure
    browser.close
  end

  def login
    form = browser.form(action: "/login")
    form.text_field(name: "email").set(username)
    form.text_field(name: "password").set(password)
    form.submit
  end
end
