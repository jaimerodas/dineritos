import { Controller } from "stimulus"
import { IRRGraph, BalanceGraph } from "../graphs/account_graphs"

export default class extends Controller {
  static targets = ["chart", "balanceButton", "irrButton"]

  connect() {
    this.balances = new BalanceGraph(this.chartTarget, window.data.balances)
    this.irrs = new IRRGraph(this.chartTarget, window.data.irrs)

    this.balances.draw()
    this.irrs.draw()

    this.irrChart = document.getElementById("irr-graph")
    this.balanceChart = document.getElementById("balance-graph")

    this.addButtons()
  }

  addButtons() {
    var balanceButton = document.createElement("button")
    balanceButton.dataset.action = "click->show-account#showBalance"
    balanceButton.dataset.target = "show-account.balanceButton"
    balanceButton.textContent = "Saldo"

    var irrButton = document.createElement("button")
    irrButton.dataset.action = "click->show-account#showIRR"
    irrButton.dataset.target = "show-account.irrButton"
    irrButton.textContent = "TIR"

    var buttonContainer = document.createElement("div")
    buttonContainer.className = "chart-toggle"
    buttonContainer.append(balanceButton, irrButton)

    this.chartTarget.append(buttonContainer)
    this.showBalance()
  }

  showIRR() {
    this.irrChart.setAttribute("style", "display: block;")
    this.balanceChart.setAttribute("style", "display: none;")
    this.balanceButtonTarget.className = ""
    this.irrButtonTarget.className = "active"
  }

  showBalance() {
    this.irrChart.setAttribute("style", "display: none;")
    this.balanceChart.setAttribute("style", "display: block;")
    this.balanceButtonTarget.className = "active"
    this.irrButtonTarget.className = ""
  }
}
