import { Controller } from '@hotwired/stimulus'
import { IRRChart, BalanceChart } from 'charts/account_charts'

export default class extends Controller {
  static targets = ['chart', 'balanceButton', 'irrButton']

  connect () {
    this.chartTarget.innerHTML = ''

    this.balances = new BalanceChart(this.chartTarget, window.data.balances)
    this.irrs = new IRRChart(this.chartTarget, window.data.irrs)

    this.balances.draw()
    this.irrs.draw()

    this.irrChart = document.getElementById('irr-chart')
    this.balanceChart = document.getElementById('balance-chart')

    this.addButtons()
  }

  addButtons () {
    const balanceButton = document.createElement('button')
    balanceButton.dataset.action = 'click->show-account#showBalance'
    balanceButton.dataset.showAccountTarget = 'balanceButton'
    balanceButton.textContent = 'Saldo'

    const irrButton = document.createElement('button')
    irrButton.dataset.action = 'click->show-account#showIRR'
    irrButton.dataset.showAccountTarget = 'irrButton'
    irrButton.textContent = 'TIR'

    const buttonContainer = document.createElement('div')
    buttonContainer.className = 'chart-toggle'
    buttonContainer.append(balanceButton, irrButton)

    this.chartTarget.append(buttonContainer)
    this.showBalance()
  }

  showIRR () {
    this.irrChart.setAttribute('style', 'display: block;')
    this.balanceChart.setAttribute('style', 'display: none;')
    this.balanceButtonTarget.className = ''
    this.irrButtonTarget.className = 'active'
  }

  showBalance () {
    this.irrChart.setAttribute('style', 'display: none;')
    this.balanceChart.setAttribute('style', 'display: block;')
    this.balanceButtonTarget.className = 'active'
    this.irrButtonTarget.className = ''
  }
}
