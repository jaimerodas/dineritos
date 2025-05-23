import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type"]
  connect() {
    this.change()
  }

  change() {
    const selected_platform = this.typeTarget.value
    const platforms = ["apify", "afluenta", "bitso", "no_platform"]
    const fields = ["apify", "afluenta" "bitso", "credentials", "no_platform"]
    const fields_to_show = platforms.includes(selected_platform) ? selected_platform : "credentials"

    fields.forEach(e => this.elementVisible(e + "_fields", e === fields_to_show))

    if (selected_platform !== "no_platform") {
      document.getElementById("account_currency").value = "MXN"
    }
  }

  elementVisible(name, visible) {
    var display = visible ? "block" : "none"
    document.getElementById(name).style.display = display
    document.querySelectorAll(`#${name} input, #${name} textarea`).forEach(e => e.disabled = !visible)
  }
}
