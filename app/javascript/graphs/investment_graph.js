import * as d3 from "d3"

class InvestmentGraph {
  height = 400

  constructor(element, data) {
    this.container = element
    this.data = data
    this.margin = ({top: 20, right: 5, bottom: 30, left: 32})
    this.width = this.container.offsetWidth + 32

    this.setLocale()

    this.svg = d3.select(this.container).append("svg")
      .attr("viewBox", [0, 0, this.width, this.height])

    this.keys = Object.keys(this.data[this.data.length - 1])
      .slice(0, Object.keys(this.data[this.data.length -1]).length -1)

    this.series = d3.stack().keys(this.keys)(this.data)

    this.color = d3.scaleOrdinal().domain(this.keys)
      .range(this.interpolateColors(this.keys.length, d3.interpolateRainbow))

    this.totals = this.series[this.series.length - 1].map(d => {
      return {date: new Date(d.data.date), value: d[1]}
    })

    this.x = d3.scaleUtc()
      .domain(d3.extent(this.data, d => new Date(d.date)))
      .range([this.margin.left, this.width - this.margin.right])

    this.y = d3.scaleLinear()
      .domain([0, d3.max(this.series, d => d3.max(d, d => d[1]))]).nice()
      .range([this.height - this.margin.bottom, this.margin.top])

    this.area = d3.area()
      .curve(d3.curveLinear)
      .x(d => this.x(new Date(d.data.date)))
      .y0(d => this.y(d[0]))
      .y1(d => this.y(d[1]))
  }

  draw() {
    const xAxis = (g) => g
      .attr("transform", `translate(0,${this.height - this.margin.bottom})`)
      .call(d3.axisBottom(this.x).ticks(this.width / 80).tickSizeOuter(0))

    const yAxis = (g) => g
      .attr("transform", `translate(${this.margin.left},0)`)
      .call(d3.axisLeft(this.y).tickFormat(d3.format(".3~s")))
      .call(g => g.selectAll(".tick line").clone()
        .attr("stroke-opacity", d => d === 0 ? null : 0.2)
        .attr("stroke-dasharray", "4, 4")
        .attr("x2", this.width - this.margin.left - this.margin.right))
      .call(g => g.select(".domain").remove())

    const drawTooltip = () => {
      d3.event.preventDefault()
      var [xCoord, yCoord] = d3.mouse(d3.event.target)
      const mouseDate = this.x.invert(xCoord)

      if (xCoord > this.width - this.margin.right) {
        xCoord = this.width - this.margin.right
      }

      const bisectDate = d3.bisector(d => d.date).left
      const xIndex = bisectDate(this.totals, mouseDate, 1)
      const mousePopulation = this.totals[xIndex - 1].value
      const mouseDateSnap = this.x(this.totals[xIndex - 1].date)

      this.svg.selectAll('.hoverLine')
        .attr('x1', mouseDateSnap)
        .attr('y1', this.margin.top)
        .attr('x2', mouseDateSnap)
        .attr('y2', this.height - this.margin.bottom)

      const isLessThanHalf = mouseDateSnap > this.width / 2
      const hoverTextX = isLessThanHalf ? '-0.25em' : '0.25em'
      const hoverTextAnchor = isLessThanHalf ? 'end' : 'start'

      this.svg.selectAll('.hoverText')
        .attr('x', mouseDateSnap)
        .attr('y', 0)
        .attr('dx', hoverTextX)
        .attr('dy', '.75em')
        .style('text-anchor', hoverTextAnchor)
        .text(d3.format("$,.2f")(mousePopulation))
    }

    this.svg.append("g")
      .selectAll("path")
      .data(this.series)
      .join("path")
        .attr("fill", ({key}) => this.color(key))
        .attr("d", this.area)
      .append("title")
        .text(({key}) => key)

    this.svg.append("g").attr("class", "axis").call(xAxis).attr("font-family", null)
    this.svg.append("g").attr("class", "axis").call(yAxis).attr("font-family", null)

    this.svg.append('line').classed('hoverLine', true)
    this.svg.append("text").classed('hoverText', true)

    this.svg.append('rect')
      .attr('fill', 'transparent')
      .attr('x', 0)
      .attr('y', 0)
      .attr('width', this.width)
      .attr('height', this.height)


    this.svg.on('mousemove', drawTooltip)
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
