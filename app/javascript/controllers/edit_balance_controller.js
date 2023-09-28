import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amount", "transfers", "diff", "irr"]
  connect() {
    this.prevAmount = parseFloat(this.element.dataset.previousBalance)
    this.diffDays = parseInt(this.element.dataset.diffDays, 10)
    this.updateResults()
  }

  updateResults() {
    this.cleanAmounts()
    this.calculateDiff()
    this.calculateIRR()
  }

  cleanAmounts() {
    let regex = /[^-\d\.]/g
    this.amountTarget.value = this.amountTarget.value.replace(regex, '')
    this.transfersTarget.value = this.transfersTarget.value.replace(regex, '')
  }

  amount() {
    return parseFloat(this.amountTarget.value)
  }

  transfers() {
    return parseFloat(this.transfersTarget.value)
  }

  calculateDiff() {
    const amount = this.amount()
    const transfers = this.transfers()

    if (amount === NaN || this.prevAmount === NaN || transfers === NaN) { return }
    const result = (amount - this.prevAmount - transfers).toLocaleString("en-us", {
      style: "decimal",
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })
    this.diffTarget.textContent = result
  }

  calculateIRR() {
    const amount = this.amount()
    const transfers = this.transfers()

    if (amount === NaN || this.prevAmount === NaN || this.diffDays === NaN || transfers === NaN) {
      return
    }

    const dailyRate = (1 + ((amount - this.prevAmount - transfers) / this.prevAmount))
    const power = 365 / this.diffDays
    const result = ((dailyRate ** power) - 1).toLocaleString("en-us", {
      style: "percent",
      maximumFractionDigits: 2
    })
    this.irrTarget.textContent = result
  }
}
// 1,100.00
