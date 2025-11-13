import { Controller } from '@hotwired/stimulus'
import * as Plot from "@observablehq/plot"
import * as d3 from "d3"

export default class extends Controller {
  static targets = ['balanceChart', 'irrChart']

  connect () {
    this.drawCharts()
  }

  drawCharts() {
    const data = window.data
    const balancesData = data.balances.map(d => ({
      date: d3.utcParse("%Y-%m-%d")(d.date),
      value: parseFloat(d.value)
    }))
    const irrsData = data.irrs.map(d => ({
      date: d3.utcParse("%Y-%m-%d")(d.date),
      value: parseFloat(d.value)
    }))

    const chartWidth = this.balanceChartTarget.offsetWidth

    const balancesChart = Plot.plot({
      padding: 0,
      height: 200,
      x: { label: "Fecha" },
      y: { label: "Saldo", tickFormat: d3.format("$.2s"), grid: true },
      marks: [
        Plot.line(balancesData, {
          x: "date",
          y: "value",
          tip: {
            format: {
              x: true,
              y: (d) => d3.format("$,.2f")(d)
            }
          }
        }),
        Plot.ruleY([0])
      ]
    })

    const irrChart = Plot.plot({
      padding: 0,
      height: 200,
      x: { label: "Fecha" },
      y: { label: "TIR", tickFormat: d3.format(".0%"),grid: true },
      marks: [
        Plot.line(irrsData, {
          x: "date",
          y: "value",
          tip: {
            format: {
              x: true,
              y: (d) => `${d3.format(".2%")(d)}`
            }
          }
        }),
        Plot.ruleY([0])
      ]
    })

    balancesChart.setAttribute("font-family", "inherit")
    irrChart.setAttribute("font-family", "inherit")

    this.balanceChartTarget.appendChild(balancesChart)
    this.irrChartTarget.appendChild(irrChart)
  }
}
