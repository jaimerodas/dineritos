import { Controller } from "stimulus"
import { InvestmentGraph } from "../graphs/investment_graph"
import { BalanceChangeGraph } from "../graphs/balance_change_graph"

export default class extends Controller {
  static targets = ["chart", "summary", "summaryButtons", "chartButtons"]

  connect() {
    this.addSummaryNav()
    this.addChartsNav()
  }

  chartGenerator(name) {
    return {"Saldos": InvestmentGraph, "Rendimientos": BalanceChangeGraph}[name]
  }

  updateSummary(event) {
    const buttons = this.summaryButtonsTarget
    const summary = this.summaryTarget

    fetch(event.target.dataset.url)
      .then(response => response.text())
      .then(html => {
        buttons
          .querySelectorAll("button.active")
          .forEach(d => d.className = "")

        event.target.className = "active"
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

  addSummaryNav() {
    if (this.summaryButtonsTarget.children.length > 0) { return }

    const createButton = (period, label) => {
      const button = document.createElement("button")
      button.dataset.action = "click->investments#updateSummary"
      button.dataset.url = this.data.get("summary-url") + "?period=" + period
      button.textContent = label
      return button
    }

    const currentYear = (new Date()).getFullYear()

    const lastYearButton = createButton("past_year", "Último Año")
    const currentCalendarYearButton = createButton(currentYear, currentYear)
    const previousCalendarYearButton = createButton(currentYear - 1, currentYear - 1)

    this.summaryButtonsTarget
      .append(lastYearButton, currentCalendarYearButton, previousCalendarYearButton)

    this.updateSummary({target: currentCalendarYearButton})
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
