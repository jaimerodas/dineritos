import { Controller } from '@hotwired/stimulus'
import ExchangeRateChart from 'charts/exchange_rate_chart'

// Controller to render USD/MXN exchange rate chart
export default class extends Controller {
  connect () {
    const url = this.element.dataset.exchangeRateChartUrl
    if (!url) {
      // Missing required data attribute
      // In development: console.error('[exchange-rate-chart] data-exchange-rate-chart-url missing')
      return
    }
    fetch(url)
      .then(response => response.json())
      .then(json => new ExchangeRateChart(this.element, json).draw())
      .catch(error => {
        // Handle chart data loading error
        // In development: console.error('[exchange-rate-chart] load error:', error)
        // Show user-friendly error or fallback
      })
  }
}
