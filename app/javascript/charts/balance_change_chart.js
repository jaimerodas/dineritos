import * as d3 from "d3"

class BalanceChangeChart {
  height = 180

  constructor(element, data) {
    this.container = element
    this.data = Object.keys(data).map(date => {
      return {
        date: this.createDateInCorrectZone(date),
        diff: data[date].diff,
        transfers: data[date].transfers,
        irr: data[date].irr
      }
    })
    this.margin = ({top: 10, right: 10, bottom: 20, left: 32})
    this.width = this.container.offsetWidth

    this.setLocale()

    this.x = d3.scaleTime()
      .domain(d3.extent(this.data, d => d.date))
      .range([this.margin.left, this.width - this.margin.right])

    this.xAxis = (g) => g.call(d3.axisBottom(this.x))
      .attr("transform", `translate(0, ${this.height - this.margin.bottom})`)
  }

  draw() {
    this.navBar = this.navBar()
    this.diffChart = this.diffChart()
    this.irrChart = this.irrChart()
    this.transfersChart = this.transfersChart()
  }

  navBar() {
    const navContainer = d3.select(this.container).append("section")
      .attr("class", "chart-options")

    const textContainer = navContainer.append("div")
    textContainer.append("span").text("Datos al mes de")

    const datum = this.data[this.data.length - 1]
    const currentDate = textContainer.append("span")
      .attr("class", "chart-date")
      .text(d3.utcFormat("%b %Y")(datum.date))

    const formContainer = navContainer.append("div")
    const followToggle = formContainer.append("input")
      .attr("id", "chartFollowToggle")
      .attr("type", "checkbox")

    formContainer.append("label")
      .attr("for", "chartFollowToggle")

    return Object.assign(navContainer.node(), {
      shouldFollow() {
        return followToggle.property("checked")
      },
      update(datum) {
        currentDate.text(d3.utcFormat("%b %Y")(datum.date))
      }
    })
  }

  irrChart() {
    const data = this.data
    const svg = this.svg("irrChart")
    const x = this.x
    const y = this.y("irr")
    const format = d3.format(".0%")

    const xAxis = this.xAxis
    const yAxis = this.yAxis(format)

    const line = d3.line().x(d => x(d.date)).y(d => y(d.irr))
    const datum = data[data.length - 1]

    svg.append("g").attr("class", "axis").call(xAxis).attr("font-family", null)
    svg.append("g").attr("class", "axis").call(yAxis, y).attr("font-family", null)

    const path = svg.append("g").append("path")
      .attr("class", "line")
      .attr("d", line(data))

    const hoverLine = svg.append("line")
      .classed('hover-line', true)
      .attr('x1', x(datum.date)).attr('x2', x(datum.date))
      .attr('y1', this.margin.top - 4)
      .attr('y2', this.height - this.margin.bottom)

    const hoverDot = svg.append("circle")
      .classed('hover-dot', true)
      .attr('cx', x(datum.date))
      .attr('cy', y(datum.irr))
      .attr("r", 3)

    const textHolder = svg.append("text")
      .attr("class", "current-data")
      .attr("text-anchor", "start")
      .attr("y", 0)

    textHolder.append("tspan")
      .attr("dy", "1em")
      .attr("x", this.margin.left + 10)
      .text("TIR")

    const currentValue = textHolder.append("tspan")
      .style("font-size", "2em")
      .style("font-weight", "900")
      .attr("dy", "0.9em")
      .attr("x", this.margin.left + 10)
      .text(d3.format(".2%")(datum.irr))

    svg.on("touchmove mousemove", (event) => {
      this.updateCharts(event)
    })

    return Object.assign(svg.node(), {
      update(datum) {
        hoverLine.attr('x1', x(datum.date)).attr('x2', x(datum.date))
        hoverDot.attr('cx', x(datum.date)).attr('cy', y(datum.irr))
        currentValue.text(d3.format(".2%")(datum.irr))
      }
    })
  }

  diffChart() {
    const data = this.data
    const svg = this.svg("diffChart")
    const x = this.x
    const y = this.y("diff")
    const format = d3.format(".3~s")

    const xAxis = this.xAxis
    const yAxis = this.yAxis(format)

    const line = d3.line().x(d => this.x(d.date)).y(d => y(d.diff))
    const datum = data[data.length - 1]

    svg.append("g").attr("class", "axis").call(xAxis).attr("font-family", null)
    svg.append("g").attr("class", "axis").call(yAxis, y).attr("font-family", null)

    const path = svg.append("g").append("path")
      .attr("class", "line")
      .attr("d", line(data))

    const hoverLine = svg.append("line")
      .classed('hover-line', true)
      .attr('x1', x(datum.date)).attr('x2', x(datum.date))
      .attr('y1', this.margin.top - 4)
      .attr('y2', this.height - this.margin.bottom)

    const hoverDot = svg.append("circle")
      .classed('hover-dot', true)
      .attr('cx', x(datum.date))
      .attr('cy', y(datum.diff))
      .attr("r", 3)

    const textHolder = svg.append("text")
      .attr("class", "current-data")
      .attr("text-anchor", "start")
      .attr("y", 0)

    textHolder.append("tspan")
      .attr("dy", "1em")
      .attr("x", this.margin.left + 10)
      .text("Rendimiento")

    const currentValue = textHolder.append("tspan")
      .style("font-size", "2em")
      .style("font-weight", "900")
      .attr("dy", "0.9em")
      .attr("x", this.margin.left + 10)
      .text(d3.format(",.2f")(this.data[this.data.length - 1].diff))

    svg.on("touchmove mousemove", (event) => {
      this.updateCharts(event)
    })

    return Object.assign(svg.node(), {
      update(datum) {
        hoverLine.attr('x1', x(datum.date)).attr('x2', x(datum.date))
        hoverDot.attr('cx', x(datum.date)).attr('cy', y(datum.diff))
        currentValue.text(d3.format(",.2f")(datum.diff))
      }
    })
  }

  transfersChart() {
    const data = this.data
    const svg = this.svg("transfersChart")
    const x = this.x
    const y = this.y("transfers")
    const format = d3.format(".3~s")

    const xAxis = this.xAxis
    const yAxis = this.yAxis(format)

    const line = d3.line().x(d => this.x(d.date)).y(d => y(d.transfers))
    const datum = data[data.length - 1]

    svg.append("g").attr("class", "axis").call(xAxis).attr("font-family", null)
    svg.append("g").attr("class", "axis").call(yAxis, y).attr("font-family", null)

    const path = svg.append("g").append("path")
      .attr("class", "line")
      .attr("d", line(data))

    const hoverLine = svg.append("line")
      .classed('hover-line', true)
      .attr('x1', x(datum.date)).attr('x2', x(datum.date))
      .attr('y1', this.margin.top - 4)
      .attr('y2', this.height - this.margin.bottom)

    const hoverDot = svg.append("circle")
      .classed('hover-dot', true)
      .attr('cx', x(datum.date))
      .attr('cy', y(datum.transfers))
      .attr("r", 3)

    const textHolder = svg.append("text")
      .attr("class", "current-data")
      .attr("text-anchor", "start")
      .attr("y", 0)

    textHolder.append("tspan")
      .attr("dy", "1em")
      .attr("x", this.margin.left + 10)
      .text("Inversión Neta")

    const currentValue = textHolder.append("tspan")
      .style("font-size", "2em")
      .style("font-weight", "900")
      .attr("dy", "0.9em")
      .attr("x", this.margin.left + 10)
      .text(d3.format(",.2f")(this.data[this.data.length - 1].transfers))

    svg.on("touchmove mousemove", (event) => {
      this.updateCharts(event)
    })

    return Object.assign(svg.node(), {
      update(datum) {
        hoverLine.attr('x1', x(datum.date)).attr('x2', x(datum.date))
        hoverDot.attr('cx', x(datum.date)).attr('cy', y(datum.transfers))
        currentValue.text(d3.format(",.2f")(datum.transfers))
      }
    })
  }

  updateCharts(event) {
    if (!this.navBar.shouldFollow()) { return }

    const mouseX = d3.pointer(event, this.container)[0]
    const x = mouseX > (this.width - this.margin.right) ? this.width - this.margin.right : mouseX
    const date = this.x.invert(x)
    const bisector = d3.bisector(d => d.date).left
    const index = bisector(this.data, date, 1)

    const a = this.data[index - 1], b = this.data[index]
    const datum = (date - a.date > b.date - date) ? b : a

    this.navBar.update(datum)
    this.diffChart.update(datum)
    this.irrChart.update(datum)
    this.transfersChart.update(datum)
  }

  createDateInCorrectZone(d) {
    let date = new Date(d)
    date.setTime(date.getTime() + date.getTimezoneOffset() * 60 * 1000)
    return date
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

  y(prop) {
    return d3.scaleLinear()
    .domain([
      d3.min([0, d3.min(this.data, d => d[prop])]),
      d3.max([0, d3.max(this.data, d => d[prop])])
    ]).nice()
    .range([this.height - this.margin.bottom, this.margin.top])
  }

  yAxis(tickFormat) {
    return (g, scale) => g.call(d3.axisLeft(scale)
        .tickFormat(tickFormat)
        .tickSize(-(this.width-this.margin.left-this.margin.right))
        .ticks(this.height / 20))
      .attr("transform", `translate(${this.margin.left}, 0)`)
      .call(g => g.selectAll(".tick:not(:first-of-type) line")
        .attr("stroke-opacity", 0.3)
        .attr("stroke-dasharray", "2,2"))
      .call(g => g.select(".domain").attr("stroke-opacity", 0))
  }

  svg(id) {
    return d3.select(this.container).append("svg")
      .attr("id", id)
      .attr("viewBox", [0, 0, this.width, this.height])
      .attr("height", this.height)
  }
}

export { BalanceChangeChart }
