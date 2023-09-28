import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "type", "currency", "apiKey", "apiSecret", "username", "password", "issuer", "secret",
    "rgtoken", "rgpassword", "rgusername"
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
      default:
        fields.push("credential")
    }
    [
      "bitso","regular","credential","twoFactor", "redGirasol"
    ].forEach(e => this[e + "FieldsVisible"](fields.includes(e)))
  }

  regularFieldsVisible(visible) {
    this.elementVisible("account_currency_field", visible)
  }

  bitsoFieldsVisible(visible) {
    this.elementVisible("bitso_account_settings_field", visible)
    this.hideCurrencyIfVisible(visible)
    this.toggleTargetAbility([this.apiKeyTarget, this.apiSecretTarget], visible)
  }

  redGirasolFieldsVisible(visible) {
    this.elementVisible("red_girasol_field", visible)
    this.hideCurrencyIfVisible(visible)
    this.toggleTargetAbility([this.rgpasswordTarget, this.rgusernameTarget, this.rgtokenTarget], visible)
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
