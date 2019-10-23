import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "balance", "dateField", "total" ]

  connect() {
    this.updateTargetDate()
    this.updateAccountBalances()
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
    var today = new Date()
    var day = today.getDate().toString().padStart(2, "0")
    var month = (today.getMonth() + 1).toString().padStart(2, "0")
    var date = `${today.getFullYear()}-${month}-${day}`

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

  updateAccountBalances() {
    this.balanceTargets
      .filter(b => b.dataset.updateable === "true")
      .forEach(this.updateAccountBalance)
  }

  updateAccountBalance(account, i) {
    var status = document.createElement("span")
    status.setAttribute("class", "refresh working")
    account.parentNode.append(status)

    fetch(`/cuentas/${account.dataset.account}/actualizar`)
      .then(response => response.text())
      .then(text => {
        var result = JSON.parse(text)

        if (!result.success) {
          status.setAttribute("class", "refresh failed")
          return
        }

        status.setAttribute("class", "refresh succeeded")
        account.value = result.balance
        account.dispatchEvent(new Event("change"))
      })
  }
}
