// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction
//
// This example controller works with specially annotated HTML like:
//
// <div data-controller="hello">
//   <h1 data-target="hello.output"></h1>
// </div>

import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "balance", "dateField", "total" ]

  connect() {
    this.updateTargetDate()
    this.totalTarget.parentNode.classList.add('active')
  }

  recalculate() {
    var total = 0.0
    this.balanceTargets.forEach((el, i) => {
      if (el.value === "") { return }
      total += this.parseBalance(el)
    })
    total = total.toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')
    this.totalTarget.textContent = `Total: ${total}`
  }

  parseBalance(balance) {
    var amount = parseFloat(balance.value)
    var currency = balance.dataset.currency
    if (currency !== "MXN") {
      amount *= this.exchangeRate(currency)
    }
    return amount
  }

  exchangeRate(currency) {
    return this.data.get(`currency-${currency.toLowerCase()}`)
  }

  currencyURL(currency, date) {
    var queryString = new URLSearchParams()
    queryString.set('currency', currency)
    queryString.set('date', this.data.get('date'))

    return this.data.get('currency-url') + '?' + queryString.toString()
  }

  updateTargetDate() {
    var date = []

    this.dateFieldTarget.querySelectorAll('select').forEach((el, i) => {
      var segment = el.value
      if (segment.length === 1) { segment = "0" + segment }
      date.push(segment)
    })

    date = date.reverse().join('-')

    if (Date.parse(date) > Date.now()) {
      throw "Invalid Date"
    }

    this.data.set('date', date)
    this.updateExchangeRate('USD')
  }

  updateExchangeRate(currency) {
    console.log(`Actualizando tipo de cambio de ${currency} para ${this.data.get('date')}`)
    fetch(this.currencyURL(currency, this.data.get('date')))
      .then(response => response.text())
      .then(text => {
        var value = JSON.parse(text).currencyRate
        this.data.set(`currency-${currency.toLowerCase()}`, value)
        console.log(`Tipo de cambio: ${value}`)
        this.recalculate()
      })
  }
}
