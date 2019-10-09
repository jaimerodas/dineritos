import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "type", "currency", "apiKey", "apiSecret" ]
  connect() {
    this.change()
  }

  change() {
    var currencyField = document.getElementById("account_currency_field")
    var settingsField = document.getElementById("account_settings_field")
    var currency = this.currencyTarget
    var type = this.typeTarget.value
    var apiKey = this.apiKeyTarget
    var apiSecret = this.apiSecretTarget

    if (type == "bitso") {
      currency.value = "MXN"
      currencyField.style.display = "none"
      settingsField.style.display = "block"
      apiKey.disabled = false
      apiSecret.disabled = false
    } else {
      currencyField.style.display = "block"
      settingsField.style.display = "none"
      apiKey.disabled = true
      apiSecret.disabled = true
    }

  }
}
