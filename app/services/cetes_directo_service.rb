class CetesDirectoService
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
    browser.goto "https://www.cetesdirecto.com/SSOSVD_wls/"
    login
    value = get_value
    logout
    BigDecimal(value.tr("^0-9.", "")).round(2)
  ensure
    browser.close
  end

  def login
    form = browser.form(action: "/obtenerAccesoWeb")
    form.text_field(id: "userId").set(username)
    browser.button(id: "continuarBtn").click
    form.text_field(id: "pwdId").set(password)
    browser.button(id: "accederBtn").click
  end

  def logout
    browser.button(data_target: "#menuLateralWeb").click
    browser.div(class: %w[bloqueMenuLateral subMenuLateralWeb], data_name: "cerrarSesion").click
  end

  def get_value
    browser.div(id: "portafolioMenu").click
    browser.div(class: %w[totalInstrumentosNumeros tituloInstrumento]).child.text
  end
end
