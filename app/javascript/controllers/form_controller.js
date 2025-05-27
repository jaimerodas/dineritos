import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['balance', 'dateField', 'total']

  connect () {
    this.updateTargetDate()
    this.totalTarget.parentNode.classList.add('active')
  }

  recalculate () {
    let total = 0.0
    this.balanceTargets.forEach((el, i) => {
      if (el.value === '') { return }
      total += this.parseBalance(el)
    })
    total = total.toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,')
    this.totalTarget.textContent = `Total: ${total}`
  }

  parseBalance (balance) {
    let amount = parseFloat(balance.value)
    const currency = balance.dataset.currency
    if (currency !== 'MXN') {
      amount *= this.exchangeRate(currency)
    }
    return amount
  }

  exchangeRate (currency) {
    return this.data.get(`currency-${currency.toLowerCase()}`)
  }

  currencyURL (currency, date) {
    const queryString = new URLSearchParams()
    queryString.set('currency', currency)
    queryString.set('date', this.data.get('date'))

    return this.data.get('currency-url') + '?' + queryString.toString()
  }

  updateTargetDate () {
    const today = new Date()
    const day = today.getDate().toString().padStart(2, '0')
    const month = (today.getMonth() + 1).toString().padStart(2, '0')
    const date = `${today.getFullYear()}-${month}-${day}`

    this.data.set('date', date)
    this.updateExchangeRate('USD')
  }

  updateExchangeRate (currency) {
    fetch(this.currencyURL(currency, this.data.get('date')))
      .then(response => response.text())
      .then(text => {
        const value = JSON.parse(text).currencyRate
        this.data.set(`currency-${currency.toLowerCase()}`, value)
        this.recalculate()
      })
  }
}
