import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "type", "currency", "apiKey", "apiSecret", "username", "password", "issuer", "secret" ]
  connect() {
    this.change()
  }

  change() {
    var type = this.typeTarget.value

    switch (type) {
      case "bitso":
        this.bitsoFieldsVisible(true)
        this.regularFieldsVisible(false)
        this.credentialFieldsVisible(false)
        this.twoFactorFieldsVisible(false)
        break
      case "no_platform":
        this.regularFieldsVisible(true)
        this.bitsoFieldsVisible(false)
        this.credentialFieldsVisible(false)
        this.twoFactorFieldsVisible(false)
        break
      case "afluenta":
        this.credentialFieldsVisible(true)
        this.bitsoFieldsVisible(false)
        this.regularFieldsVisible(false)
        this.twoFactorFieldsVisible(true)
        break
      default:
        this.credentialFieldsVisible(true)
        this.bitsoFieldsVisible(false)
        this.regularFieldsVisible(false)
        this.twoFactorFieldsVisible(false)
    }
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
    targets.map(e => e.disabled = !enabled)
  }
}
