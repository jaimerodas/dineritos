import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "type", "currency", "apiKey", "apiSecret", "username", "password" ]
  connect() {
    this.change()
  }

  change() {
    var type = this.typeTarget.value

    switch (type) {
      case "bitso":
        this.enableBitsoFields()
        this.disableRegularFields()
        this.disableCredentialsFields()
        break
      case "no_platform":
        this.enableRegularFields()
        this.disableBitsoFields()
        this.disableCredentialsFields()
        break
      default:
        this.enableCredentialsFields()
        this.disableBitsoFields()
        this.disableRegularFields()
    }
  }

  enableRegularFields() {
    document.getElementById("account_currency_field").style.display = "block"
  }

  disableRegularFields() {
    document.getElementById("account_currency_field").style.display = "none"
  }

  enableBitsoFields() {
    document.getElementById("bitso_account_settings_field").style.display = "block"
    document.getElementById("account_currency_field").value = "MXN"
    this.apiKeyTarget.disabled = false
    this.apiSecretTarget.disabled = false
  }

  disableBitsoFields() {
    document.getElementById("bitso_account_settings_field").style.display = "none"
    this.apiKeyTarget.disabled = true
    this.apiSecretTarget.disabled = true
  }

  enableCredentialsFields() {
    document.getElementById("account_settings_credentials_field").style.display = "block"
    document.getElementById("account_currency_field").value = "MXN"
    this.usernameTarget.disabled = false
    this.passwordTarget.disabled = false
  }

  disableCredentialsFields() {
    document.getElementById("account_settings_credentials_field").style.display = "none"
    this.usernameTarget.disabled = true
    this.passwordTarget.disabled = true
  }
}
