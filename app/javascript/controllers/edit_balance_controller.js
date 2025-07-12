import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['amount', 'transfers', 'diff', 'irr']
  connect () {
    this.prevAmount = parseFloat(this.element.dataset.previousBalance)
    this.diffDays = parseInt(this.element.dataset.diffDays, 10)
    this.isFirst = (this.element.dataset.isFirst === 'true')
    this.updateResults()
  }

  updateResults () {
    this.cleanAmounts()
    if (this.isFirst) { this.updateInitialTransfers() }
    this.calculateDiff()
    this.calculateIRR()
  }

  cleanAmounts () {
    const regex = /[^-\d.]/g
    this.amountTarget.value = this.amountTarget.value.replace(regex, '')
    this.transfersTarget.value = this.transfersTarget.value.replace(regex, '')
  }

  amount () {
    return parseFloat(this.amountTarget.value)
  }

  transfers () {
    return parseFloat(this.transfersTarget.value)
  }

  updateInitialTransfers() {
    this.transfersTarget.value = this.amount()
  }

  calculateDiff () {
    const amount = this.amount()
    const transfers = this.transfers()

    if (Number.isNaN(amount) || Number.isNaN(this.prevAmount) || Number.isNaN(transfers)) { return }
    const result = (amount - this.prevAmount - transfers).toLocaleString('en-us', {
      style: 'decimal',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })
    this.diffTarget.textContent = result
  }

  calculateIRR () {
    const amount = this.amount()
    const transfers = this.transfers()

    if (Number.isNaN(amount) || Number.isNaN(this.prevAmount) ||
        Number.isNaN(this.diffDays) || Number.isNaN(transfers)) {
      this.irrTarget.textContent = '-'
      return
    }

    const dailyRate = (1 + ((amount - this.prevAmount - transfers) / this.prevAmount))
    const power = 365 / this.diffDays
    let result = ((dailyRate ** power) - 1).toLocaleString('en-us', {
      style: 'percent',
      maximumFractionDigits: 2
    })

    if (result === 'NaN%') { result = '-' }

    this.irrTarget.textContent = result
  }
}
// 1,100.00
