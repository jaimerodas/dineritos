import * as d3 from "d3"

class IRRChart {
  constructor(element, data) {
    this.container = element
    this.data = data
    this.setLocale()
  }

  name() {
    return "irr-chart"
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
      .domain([
        d3.min(data, d => d.value),
        d3.max([0, d3.max(data, d => d.value)])
      ]).nice()
      .range([height - margin.bottom, margin.top])

    const xAxis = g => g
      .attr("transform", `translate(0, ${height - margin.bottom})`)
      .call(d3.axisBottom(x))

    const yAxis = g => g
      .attr("transform", `translate(${margin.left}, 0)`)
      .call(d3.axisLeft(y)
        .tickFormat(this.axisFormatter())
        .tickSize(-(width-margin.left-margin.right))
        .ticks(10))
      .call(g => g.selectAll(".tick:not(:first-of-type) line")
        .attr("stroke-opacity", 0.3)
        .attr("stroke-dasharray", "2,2"))
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
      .attr("stroke-width", 2)
      .attr("stroke-opacity", 0.5)
      .attr("stroke-linejoin", "round")
      .attr("stroke-linecap", "round")
      .attr("d", line)

    const hoverLine = svg.append("line")
      .classed('hover-line', true)
      .attr('y1', margin.top - 4)
      .attr('y2', height - margin.bottom)

    const hoverDot = svg.append("circle").attr("r", 4).attr("fill", "var(--fg-color)")
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

    svg.on("touchmove mousemove", (event) => {
      const {date, value} = bisect(d3.pointer(event, this.container)[0])

      tooltip
        .attr("transform", `translate(${width - margin.right}, ${height - 60})`)
        .call(
          this.callout,
          `${this.valueFormatter(value)}|${this.dateFormatter(date)}`)

      hoverDot.attr('cx', x(date)).attr('cy', y(value))

      hoverLine.attr('x1', x(date)).attr('x2', x(date))
    })
  }

  curve() {
    return d3.curveLinear
  }

  valueFormatter(value) {
    return d3.format(".2~%")(value)
  }

  dateFormatter(value) {
    return d3.utcFormat("%b %Y")(value)
  }

  axisFormatter() {
    return d3.format(".0%")
  }

  callout(g, value) {
    g.style("display", null)
      .style("pointer-events", "none")
      .style("text-anchor", "end")
      .style("fill", "var(--fg-color)")

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
      .style("font-size", (_, i) => i ? "1em" : "1.5em")
      .style("opacity", (_, i) => i ? 0.5 : 1)
      .text(d => d))
  }

  setLocale() {
    d3.timeFormatDefaultLocale({
      dateTime: "%x, %X",
      date: "%d/%m/%Y",
      time: "%-I:%M:%S %p",
      periods: ["AM", "PM"],
      days: ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"],
      shortDays: ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"],
      months: ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"],
      shortMonths: ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
    })
  }
}

class BalanceChart extends IRRChart {
  name() {
    return "balance-chart"
  }

  curve() {
    return d3.curveStepAfter
  }

  axisFormatter() {
    return d3.format(".3~s")
  }

  valueFormatter(value) {
    return d3.format(",.2f")(value)
  }

  dateFormatter(value) {
    return d3.utcFormat("%Y-%m-%d")(value)
  }
}

export { IRRChart, BalanceChart }
