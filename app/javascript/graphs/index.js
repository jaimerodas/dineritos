import * as d3 from "d3"

const context = require.context("controllers", true, /_graph\.js$/)

class IRRGraph {
  constructor(element, data) {
    this.container = element
    this.data = data
    this.setLocale()
  }

  name() {
    return "irr-graph"
  }

  draw() {
    const width = this.container.offsetWidth + 32;
    const height = 300
    const margin = {top: 20, right: 39, bottom: 30, left: 39}

    const data = this.data

    const svg = d3.select(this.container).append("svg")
      .attr("id", this.name)
      .attr("width", width)
      .attr("height", height)

    const x = d3.scaleUtc()
      .domain(d3.extent(data, d => d.date))
      .range([margin.left, width - margin.right])

    const y = d3.scaleLinear()
      .domain([this.axisFloor(), d3.max(data, d => d.value)]).nice()
      .range([height - margin.bottom, margin.top])

    const xAxis = g => g
      .attr("transform", `translate(0, ${height - margin.bottom})`)
      .call(d3.axisBottom(x).ticks(width / 80).tickSizeOuter(0))

    const yAxis = g => g
      .attr("transform", `translate(${margin.left},0)`)
      .call(d3.axisLeft(y).tickFormat(this.axisFormatter()))
      .call(g => g.selectAll(".tick line").clone()
        .attr("stroke-opacity", d => d === 0 ? null : 0.2)
        .attr("stroke-dasharray", "4, 4")
        .attr("x2", width - margin.left - margin.right))
      .call(g => g.select(".domain").remove())

    const line = d3.line()
      .curve(this.curve())
      .defined(d => !isNaN(d.value))
      .x(d => x(d.date))
      .y(d => y(d.value))

    svg.append("g").attr("class", "axis")
      .call(xAxis).attr("font-family", null)
    svg.append("g").attr("class", "axis")
      .call(yAxis).attr("font-family", null)

    svg.append("path")
      .datum(data)
      .attr("fill", "none")
      .attr("stroke", "var(--fg-color)")
      .attr("stroke-width", 3)
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("d", line)

    const tooltip = svg.append("g")

    const bisect = (mx) => {
      if (mx > (width - margin.right)) {
        mx = width - margin.right
      }

      const bisect = d3.bisector(d => d.date).left
      const date = x.invert(mx)
      const index = bisect(data, date, 1)
      const a = data[index - 1]
      const b = data[index]

      return date - a.date > b.date - date ? b : a
    }

    svg.on("touchmove mousemove", () => {
      const {date, value} = bisect(d3.mouse(this.container)[0])

      tooltip
        .attr("transform", `translate(${x(date)}, ${y(value)})`)
        .call(
          this.callout,
          `${this.valueFormatter(value)}|${this.dateFormatter(date)}`)
    })

    svg.on("touchend mouseleave", () => tooltip.call(this.callout, null))
  }

  curve() {
    return d3.curveLinear
  }

  axisFloor() {
    return d3.min([0, d3.min(this.data, d => d.value)])
  }

  axisFormatter() {
    return d3.format(".0%")
  }

  valueFormatter(value) {
    return d3.format(".2~%")(value)
  }

  dateFormatter(value) {
    return d3.timeFormat("%Y-%m")(value)
  }

  callout(g, value) {
    if (!value) return g.style("display", "none")

    g.style("display", null)
      .style("pointer-events", "none")
      .style("font-size", "0.75em")
      .style("text-anchor", "center")
      .style("fill", "var(--fg-color)")

    const box = g.selectAll("rect")
      .data([null])
      .join("rect")
      .attr("fill", "var(--bg-color)")
      .attr("stroke", "var(--fg-color)")
      .attr("stroke-width", 2)

    const text = g.selectAll("text")
      .data([null])
      .join("text")
      .call(text => text
      .selectAll("tspan")
      .data((value + "").split("|"))
      .join("tspan")
      .attr("x", 0)
      .attr("y", (d, i) => `${i * 1.1}em`)
      .style("font-weight", (_, i) => i ? null : "bold")
      .text(d => d))

    const {x, y, width: w, height: h} = text.node().getBBox()

    const width = w + 10
    const height = h + 10

    text.attr("text-anchor", "middle")
    box.attr("width", width).attr("height", height)
      .attr("transform", `translate(${-width / 2},${(-height/2)+3})`)

  }

  setLocale() {
    d3.timeFormatDefaultLocale({
      dateTime: "%x, %X",
      date: "%d/%m/%Y",
      time: "%-I:%M:%S %p",
      periods: ["AM", "PM"],
      days: ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"],
      shortDays: ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"],
      months: ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"],
      shortMonths: ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
    })
  }
}

class BalanceGraph extends IRRGraph {
  name() {
    return "balance-graph"
  }

  curve() {
    return d3.curveStepAfter
  }

  axisFloor() {
    return d3.min(this.data, d => d.value)
  }

  axisFormatter() {
    return d3.format(".3~s")
  }

  valueFormatter(value) {
    return d3.format(",.2f")(value)
  }

  dateFormatter(value) {
    return d3.timeFormat("%Y-%m-%d")(value)
  }
}

export { IRRGraph, BalanceGraph }
