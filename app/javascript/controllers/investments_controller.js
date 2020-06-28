import { Controller } from "stimulus"
import { InvestmentChart } from "../charts/investment_chart"
import { BalanceChangeChart } from "../charts/balance_change_chart"

export default class extends Controller {
  static targets = ["chart", "summary", "summaryButtons", "chartButtons"]

  connect() {
    this.addChartsNav()
  }

  chartGenerator(name) {
    return {"Saldos": InvestmentChart, "Rendimientos": BalanceChangeChart}[name]
  }

  updateSummary(event) {
    event.preventDefault()

    const buttons = this.summaryButtonsTarget
    const summary = this.summaryTarget

    fetch(event.target.dataset.url)
      .then(response => response.text())
      .then(html => {
        buttons
          .querySelectorAll("a.active")
          .forEach(d => d.classList.remove("active"))

        event.target.classList.add("active")
        summary.innerHTML = html
      })
  }

  updateChart(event) {
    const buttons = this.chartButtonsTarget
    const chartContainer = this.chartTarget
    const chartGenerator = this.chartGenerator(event.target.textContent)

    fetch(event.target.dataset.url)
      .then(response => response.text())
      .then(raw => {
        buttons
          .querySelectorAll("button.active")
          .forEach(d => d.className = "")
        event.target.className = "active"

        chartContainer.innerHTML = ''
        new chartGenerator(this.chartTarget, JSON.parse(raw)).draw()
      })
  }

  addChartsNav() {
    if (this.chartButtonsTarget.children.length > 0) { return }

    const createButton = (label, url) => {
      const button = document.createElement("button")
      button.dataset.action = "click->investments#updateChart"
      button.dataset.url = this.data.get("chart-url") + url
      button.textContent = label
      return button
    }

    const allBalancesButton = createButton("Saldos", "saldos")
    const returnsButton = createButton("Rendimientos", "rendimientos")

    this.chartButtonsTarget.append(allBalancesButton, returnsButton)
    this.updateChart({target: allBalancesButton})
  }
}
