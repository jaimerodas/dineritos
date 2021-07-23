import { Controller } from "stimulus"
import { InvestmentChart } from "../charts/investment_chart"
import { BalanceChangeChart } from "../charts/balance_change_chart"

export default class extends Controller {
  static targets = ["chart", "summary", "summaryButtons", "chartButtons"]

  connect() {
    this.addYearNav()
    this.addChartsNav()
  }

  chartGenerator(name) {
    return {"Saldos": InvestmentChart, "Rendimientos": BalanceChangeChart}[name]
  }

  changeYear(operator) {
    const buttons = this.summaryButtonsTarget
    const yearButton = buttons.querySelector("a.year")
    const year = Number(yearButton.innerHTML) + Number(operator)

    yearButton.innerHTML = year
    yearButton.dataset.url = yearButton.dataset.url.replace(/\d{4}$/, year)
    yearButton.click()

    this.addYearNav()
  }

  nextYear() {
    this.changeYear(1)
  }

  prevYear() {
    this.changeYear(-1)
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

  addYearNav() {
    this.summaryButtonsTarget.querySelectorAll("button, a").forEach((e,i) => {
      if (i > 1) { e.remove() }
    })

    const createButton = (label) => {
      const button = document.createElement("button")
      button.dataset.action = `click->investments#${label}Year`
      button.innerHTML = (label == "prev") ? "&raquo;" : "&laquo;"
      return button
    }

    const year = Number(this.summaryButtonsTarget.querySelector("a.year").innerHTML)

    if (year !== new Date().getFullYear()) {
      this.summaryButtonsTarget.append(createButton("next"))
    }

    if (year !== Number(this.summaryTarget.dataset.earliestYear)) {
      this.summaryButtonsTarget.append(createButton("prev"))
    }
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
