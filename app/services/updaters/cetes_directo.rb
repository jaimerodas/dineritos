class Updaters::CetesDirecto < BaseScraper
  def self.current_balance_for(account)
    new(account, headless: false).run
  end

  private

  def login_url
    "https://www.cetesdirecto.com/SSOSVD_wls/login.jsp"
  end

  def login
    form = browser.form(id: "accesoWebForm")
    form.text_field(id: "userId").set(username)
    browser.execute_script("obtenerAccesoWeb()")
    form.text_field(id: "pwdId").set(password)
    browser.execute_script("loginWeb()")
  end

  def logout
    browser.execute_script("cerrarSesion()")
  end

  def raw_value
    browser.div(id: "portafolioMenu").click
    browser.div(class: %w[totalInstrumentosNumeros tituloInstrumento]).child.text
  end
end
