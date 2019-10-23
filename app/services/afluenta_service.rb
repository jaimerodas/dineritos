class AfluentaService
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
    browser.goto "https://www.afluenta.mx/mi_afluenta/ingresar"
    login
    browser.goto "https://www.afluenta.mx/render/controlpanel/lender_account_summary"
    value = browser.div(id: "content").child.child.child.children[1].child.child.children[1].text
    BigDecimal(value.tr("^0-9.", "")).round(2)
  ensure
    browser.close
  end

  def login
    form = browser.form(id: "session_bar_form_login")
    form.text_field(id: "login_username").set(username)
    form.text_field(id: "login_password").set(password)
    form.submit
  end
end
