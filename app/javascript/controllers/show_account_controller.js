import { Controller } from "stimulus"
import Graph from "graphs"

export default class extends Controller {
  static targets = ["chart"]

  connect() {
    this.chart = new Graph(this.chartTarget)
    this.chart.draw()
  }
}
