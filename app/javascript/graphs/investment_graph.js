import * as d3 from "d3"

class InvestmentGraph {
  height = 250
  barChartHeight = 350

  constructor(element, data) {
    this.container = element
    this.data = data.balances
    this.margin = ({top: 20, right: 10, bottom: 30, left: 32})
    this.barMargins = ({top: 20, right: 20, bottom: 0, left: 10})
    this.width = this.container.offsetWidth

    this.setLocale()

    this.svg = d3.select(this.container).append("svg")
      .attr("id", "histogram")
      .attr("viewBox", [0, 0, this.width, this.height])
      .attr("height", this.height)

    this.bsvg = d3.select(this.container).append("svg")
      .attr("id", "barChart")
      .attr("viewBox", [0, 0, this.width, this.barChartHeight])
      .attr("height", this.barChartHeight)

    this.accounts = data.accounts
    this.keys = Object.keys(this.accounts)

    this.series = d3.stack().keys(this.keys)(this.data)

    this.color = d3.scaleOrdinal().domain(this.keys)
      .range(this.interpolateColors(this.keys.length, d3.interpolateRainbow))

    this.totals = Object.entries(this.data).map(d => {
      return {date: new Date(d[1].date), value: d3.sum(Object.values(d[1]))}
    })

    this.barData = (index) => {
      const dataset = this.data[index]
      return this.keys.map(d => ({ key: d, value: dataset[d] }))
    }

    this.x = d3.scaleUtc()
      .domain(d3.extent(this.data, d => new Date(d.date)))
      .range([this.margin.left, this.width - this.margin.right])

    this.y = d3.scaleLinear()
      .domain([0, d3.max(this.series, d => d3.max(d, d => d[1]))]).nice()
      .range([this.height - this.margin.bottom, this.margin.top])

    this.lastDate = this.data.length - 1

    this.barX = d3.scaleLinear()
      .domain([0, d3.max(this.barData(this.lastDate), d => d.value)])
      .range([this.barMargins.left, this.width - this.barMargins.right])

    this.barY = d3.scaleBand()
      .domain(this.keys)
      .range([this.barMargins.top, this.barChartHeight - this.barMargins.bottom])
      .padding(0.1)

    this.area = d3.area()
      .curve(d3.curveLinear)
      .x(d => this.x(new Date(d.data.date)))
      .y0(d => this.y(d[0]))
      .y1(d => this.y(d[1]))

    this.barXAxis = g => g
      .attr("transform", `translate(0, ${this.barMargins.top})`)
      .call(d3.axisTop(this.barX)
      .ticks(this.width > 400 ? 10 : 6, ".3~s")
      .tickSize(-(this.barChartHeight-this.barMargins.top-this.barMargins.bottom)))
      .call(g => g.selectAll(".tick:not(:first-of-type) line")
        .attr("stroke-opacity", 0.3)
        .attr("stroke-dasharray", "2,2"))
      .call(g => g.select(".domain").attr("stroke-opacity", 0))
  }

  draw() {
    this.stackedAreaChart()
    this.barChart = this.barChart()
  }

  barChart() {
    const dataAccessor = this.barData
    const accounts = this.accounts
    const barX = this.barX
    const barY = this.barY
    const barXAxis = this.barXAxis
    const margin = this.barMargins
    const data = dataAccessor(this.lastDate)
    const bsvg = this.bsvg
    const formatCurrency = this.formatCurrency

    const labelTransform = (d) => {
      const xOffset = d3.max([barX(d.value) - 10, margin.left + 100])
      const yOffset = barY(d.key) + barY.bandwidth() / 2
      return `translate(${xOffset}, ${yOffset})`
    }

    const detailsHTML = (d) => {
      return `<tspan dy="-0.15em" dx="0.4em" x="0" y="0">${accounts[d.key].name}</tspan>
              <tspan class="money" dy="0.85em" dx="0" x="0" y="0">${formatCurrency(d)}</tspan>`
    }

    const bars = bsvg.append("g")
      .attr("class", "color-container")
      .selectAll("a")
      .data(data)
      .join("a")
      .attr("xlink:href", d => accounts[d.key].url)
      .append("rect")
      .attr("fill", d => this.color(d.key))
      .attr("x", barX(0))
      .attr("y", d => barY(d.key))
      .attr("width", d => barX(d.value) - barX(0))
      .attr("height", barY.bandwidth())

    const details = bsvg.append("g")
      .attr("class", "barchart-text")
      .attr("text-anchor", "end")
      .selectAll("a")
      .data(data)
      .join("a")
      .attr("xlink:href", d => accounts[d.key].url)
      .append("text")
      .attr("transform", labelTransform)
      .style("fill-opacity", d => (d.value > 0) ? "1" : "0")
      .html(detailsHTML)

    const xAxis = bsvg.append("g").attr("class", "axis").call(barXAxis).attr("font-family", null)

    return Object.assign(bsvg.node(), {
      update(index) {
        const data = dataAccessor(index)
        const t = bsvg.transition().duration(200).ease(d3.easeLinear)

        barX.domain([0, d3.max(data, d => d.value)])

        bars.data(data, d => d.key).order().transition(t)
          .attr("width", d => barX(d.value) - barX(0))
          .attr("y", d => barY(d.key))

        details.data(data, d => d.key).order().transition(t)
          .attr("transform", labelTransform)
          .style("fill-opacity", d => (d.value > 0) ? "1" : "0")
          .select("tspan.money").text(formatCurrency)

        xAxis.transition(t).call(barXAxis)
      }
    })
  }

  stackedAreaChart() {
    const formatCurrency = this.formatCurrency
    const formatDate = d3.utcFormat("%Y-%m-%d")
    const xAxis = (g) => g
      .attr("transform", `translate(0,${this.height - this.margin.bottom})`)
      .call(d3.axisBottom(this.x).ticks(this.width / 80).tickSizeOuter(0))

    const yAxis = (g) => g
      .attr("transform", `translate(${this.margin.left},0)`)
      .call(d3.axisLeft(this.y)
        .tickFormat(d3.format(".3~s"))
        .tickSize(-(this.width-this.margin.left-this.margin.right)))
      .call(g => g.selectAll(".tick:not(:first-of-type) line")
        .attr("stroke-opacity", 0.3)
        .attr("stroke-dasharray", "2,2"))
      .call(g => g.select(".domain").attr("stroke-opacity", 0))

    const drawTooltip = () => {
      d3.event.preventDefault()

      const [xCoord, _] = d3.mouse(d3.event.target)
      const bisectDate = d3.bisector(d => d.date).left
      const xIndex = bisectDate(this.totals, this.x.invert(xCoord), 1) - 1
      const datum = this.totals[xIndex]
      const dateSnap = this.x(datum.date)

      hoverLine.attr('x1', dateSnap).attr('x2', dateSnap)

      d3.select("#charts dd").text(formatCurrency(datum))
      d3.select("#charts time")
        .attr("datetime", formatDate(datum.date))
        .text(formatDate(datum.date))

      this.barChart.update(xIndex)
    }

    this.svg.append("g")
      .selectAll("path")
      .data(this.series)
      .join("path")
        .attr("fill", ({key}) => this.color(key))
        .attr("class", "color-container")
        .attr("d", this.area)

    this.svg.append("g").attr("class", "axis").call(xAxis).attr("font-family", null)
    this.svg.append("g").attr("class", "axis").call(yAxis).attr("font-family", null)

    const dateSnap = this.x(this.totals[this.lastDate].date)

    const hoverLine = this.svg.append("line")
      .classed('hoverLine', true)
      .attr('x1', dateSnap).attr('x2', dateSnap)
      .attr('y1', this.margin.top)
      .attr('y2', this.height - this.margin.bottom)

    this.svg.append('rect')
      .attr('fill', 'transparent')
      .attr('x', 0).attr('y', 0)
      .attr('width', this.width).attr('height', this.height)

    this.svg.on('touchmove mousemove', drawTooltip)
  }

  formatCurrency(d) {
    return d3.format(",.2f")(d.value)
  }

  interpolateColors(dataLength, colorScale) {
    let intervalSize = 1 / dataLength
    let i, colorPoint
    let colorArray = []

    for (i = 0; i < dataLength; i++) {
      colorPoint = (i * intervalSize)
      colorArray.push(colorScale(colorPoint))
    }

    return colorArray
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

export { InvestmentGraph }
