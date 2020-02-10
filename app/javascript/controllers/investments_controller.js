import { Controller } from "stimulus"
import { InvestmentGraph } from "../graphs/investment_graph"

export default class extends Controller {
  static targets = ["chart", "summary", "summaryButtons"]

  connect() {
    this.investments = new InvestmentGraph(this.chartTarget, window.data)
    this.investments.draw()
    this.addButtons()
  }

  updateSummary(event) {
    const buttons = this.summaryButtonsTarget
    const summary = this.summaryTarget

    fetch(event.target.dataset.url)
      .then(response => response.text())
      .then(html => {
        buttons
          .querySelectorAll("button.active")
          .forEach((el) => el.className = "")

        event.target.className = "active"
        summary.innerHTML = html
      })
  }

  addButtons() {
    const createButton = (period, text) => {
      const button = document.createElement("button")
      button.dataset.action = "click->investments#updateSummary"
      button.dataset.url = this.data.get("summary-url") + "?period=" + period
      button.textContent = text
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
}
