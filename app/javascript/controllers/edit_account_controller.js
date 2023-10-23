import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "type", "currency", "apiKey", "apiSecret", "username", "password", "issuer", "secret",
    "rgtoken", "rgpassword", "rgusername", "apusername", "appassword", "aptoken", "apactor"
  ]
  connect() {
    this.change()
  }

  change() {
    var fields = new Array

    switch (this.typeTarget.value) {
      case "bitso":
        fields.push("bitso")
        break
      case "no_platform":
        fields.push("regular")
        break
      case "afluenta":
        fields.push("twoFactor")
      case "red_girasol":
        fields.push("redGirasol")
        break
      case "apify":
        fields.push("apify")
        break
      default:
        fields.push("credential")
    }
    [
      "bitso","regular","credential","afluenta", "redGirasol", "apify"
    ].forEach(e => this[e + "FieldsVisible"](fields.includes(e)))
  }

  regularFieldsVisible(visible) {
    this.elementVisible("account_currency_field", visible)
  }

  bitsoFieldsVisible(visible) {
    this.elementVisible("bitso_account_settings_field", visible)
    this.hideCurrencyIfVisible(visible)
  }

  redGirasolFieldsVisible(visible) {
    this.elementVisible("red_girasol_field", visible)
    this.hideCurrencyIfVisible(visible)
  }

  credentialFieldsVisible(visible) {
    this.elementVisible("account_settings_credentials_field", visible)
    this.hideCurrencyIfVisible(visible)
  }

  afluentaFieldsVisible(visible) {
    this.elementVisible("afluenta_field", visible)
  }

  apifyFieldsVisible(visible) {
    this.hideCurrencyIfVisible(visible)
    this.elementVisible("apify_field", visible)
  }

  elementVisible(name, visible) {
    var display = visible ? "block" : "none"
    document.getElementById(name).style.display = display
    document.querySelectorAll(`#${name} input, #${name} textarea`).forEach(e => e.disabled = !visible)
  }

  hideCurrencyIfVisible(visible) {
    if (visible) { return }
    document.getElementById("account_currency_field").value = "MXN"
  }
}
