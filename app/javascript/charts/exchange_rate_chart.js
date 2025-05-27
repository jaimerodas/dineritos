import * as d3 from 'd3'
import { IRRChart } from 'charts/account_charts'

// Line chart for USD/MXN exchange rate (numeric formatting)
export default class ExchangeRateChart extends IRRChart {
  name () {
    return 'exchange-rate-chart'
  }

  // Straight line curve
  curve () {
    return d3.curveLinear
  }

  // Format axis ticks with two decimals
  axisFormatter () {
    return d3.format('.2f')
  }

  // Format hover value with two decimals
  valueFormatter (value) {
    return d3.format('.2f')(value)
  }

  dateFormatter (date) {
    return d3.utcFormat('%e %b %Y')(date)
  }
}
