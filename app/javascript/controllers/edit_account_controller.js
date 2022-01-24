import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "type", "currency", "apiKey", "apiSecret", "username", "password", "issuer", "secret" ]
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
      default:
        fields.push("credential")
    }
    ["bitso","regular","credential","twoFactor"].forEach(e => this[e + "FieldsVisible"](fields.includes(e)))
  }

  regularFieldsVisible(visible) {
    this.elementVisible("account_currency_field", visible)
  }

  bitsoFieldsVisible(visible) {
    this.elementVisible("bitso_account_settings_field", visible)
    this.hideCurrencyIfVisible(visible)
    this.toggleTargetAbility([this.apiKeyTarget, this.apiSecretTarget], visible)
  }

  credentialFieldsVisible(visible) {
    this.elementVisible("account_settings_credentials_field", visible)
    this.hideCurrencyIfVisible(visible)
    this.toggleTargetAbility([this.usernameTarget, this.passwordTarget], visible)
  }

  twoFactorFieldsVisible(visible) {
    this.elementVisible("two_factor_field", visible)
    this.toggleTargetAbility([this.issuerTarget, this.secretTarget], visible)
  }

  elementVisible(name, visible) {
    var display = visible ? "block" : "none"
    document.getElementById(name).style.display = display
  }

  hideCurrencyIfVisible(visible) {
    if (visible) { return }
    document.getElementById("account_currency_field").value = "MXN"
  }

  toggleTargetAbility(targets, enabled) {
    targets.forEach(e => e.disabled = !enabled)
  }
}
