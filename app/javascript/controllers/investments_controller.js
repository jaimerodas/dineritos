import { Controller } from "stimulus"
import { InvestmentGraph } from "../graphs/investment_graph"

export default class extends Controller {
  static targets = ["chart"]

  connect() {
    this.investments = new InvestmentGraph(this.chartTarget, window.data)
    this.investments.draw()
  }
}
