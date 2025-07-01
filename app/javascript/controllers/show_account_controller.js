import { Controller } from '@hotwired/stimulus'
import { IRRChart, BalanceChart } from 'charts/account_charts'

export default class extends Controller {
  static targets = ['balanceChart', 'irrChart']

  connect () {
    this.balances = new BalanceChart(this.balanceChartTarget, window.data.balances)
    this.irrs = new IRRChart(this.irrChartTarget, window.data.irrs)

    this.balances.draw()
    this.irrs.draw()
  }
}
