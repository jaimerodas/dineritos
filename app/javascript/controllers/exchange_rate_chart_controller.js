import { Controller } from '@hotwired/stimulus'
import ExchangeRateChart from 'charts/exchange_rate_chart'

// Controller to render USD/MXN exchange rate chart
export default class extends Controller {
  connect () {
    const url = this.element.dataset.exchangeRateChartUrl
    if (!url) {
      console.error('[exchange-rate-chart] data-exchange-rate-chart-url missing')
      return
    }
    fetch(url)
      .then(response => response.json())
      .then(json => {
        const data = json.map(d => ({ date: new Date(d.date), value: +d.value }))
        new ExchangeRateChart(this.element, data).draw()
      })
      .catch(error => console.error('[exchange-rate-chart] load error:', error))
  }
}
