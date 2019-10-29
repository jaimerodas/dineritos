class CetesDirectoService < BalanceReaderService
  private

  def login_url
    "https://www.cetesdirecto.com/SSOSVD_wls/"
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

  def get_raw_value
    browser.div(id: "portafolioMenu").click
    browser.div(class: %w[totalInstrumentosNumeros tituloInstrumento]).child.text
  end
end
