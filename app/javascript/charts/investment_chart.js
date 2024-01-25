import * as d3 from "d3"

class InvestmentChart {
  height = 250

  constructor(element, data) {
    this.container = element
    this.data = data.balances.map(d => {
      d.date = this.createDateInCorrectZone(d.date)
      return d
    })

    this.totals = Object.entries(this.data).map(d => {
      return {
        date: d[1].date,
        value: d3.sum(Object.values(d[1]).filter(d => !(d instanceof Date)))
      }
    })

    this.margin = ({top: 10, right: 10, bottom: 30, left: 32})
    this.width = this.container.offsetWidth
    this.accounts = data.accounts
    this.keys = Object.keys(this.accounts)

    this.setLocale()

    this.series = d3.stack().keys(this.keys)(this.data)

    this.color = d3.scaleOrdinal().domain(this.keys)
      .range(this.interpolateColors(this.keys.length, d3.interpolateRainbow))

    this.lastDate = this.data.length - 1

    this.x = d3.scaleTime()
      .domain(d3.extent(this.data, d => d.date))
      .range([this.margin.left, this.width - this.margin.right])
  }

  draw() {
    this.navBar = this.navBar()
    this.stackedAreaChart = this.stackedAreaChart()
    this.barChart = this.barChart()
  }

  navBar() {
    const navContainer = d3.select(this.container).append("section")
      .attr("class", "chart-options")

    const textContainer = navContainer.append("div")
    textContainer.append("span").text("Datos al")

    const datum = this.data[this.lastDate]
    const currentDate = textContainer.append("span")
      .attr("class", "chart-date")
      .text(d3.utcFormat("%Y-%m-%d")(datum.date))

    const reportLink = textContainer.append("a")
      .attr("class", "report-link")
      .attr("href", "/reportes/diarios?d=" + d3.utcFormat("%Y-%m-%d")(datum.date))
      .text("Más info")

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
        const fDate = d3.utcFormat("%Y-%m-%d")(datum.date)
        currentDate.text(fDate)
        reportLink.attr("href", "/reportes/diarios?d=" + fDate)
      }
    })
  }

  barChart() {
    const nonZeroAccounts = this.data.map(d => {
      return Object.values(d).filter(e => e > 0).length - 1
    })

    const data = this.data.map((d, index) => {
      const row = Array.from(this.keys, key => ({
        account: this.accounts[key].name,
        url: this.accounts[key].url,
        value: d[key] ? d[key] : 0,
        id: key
      }))
      row.sort((a,b) => d3.descending(a.value, b.value))
      for (let i = 0; i < row.length; ++i) row[i].rank = Math.min(nonZeroAccounts[index], i)
      return row
    })

    const bottomRange = (i) => {
      return height - margin.bottom + (this.keys.length * 36 / nonZeroAccounts[i])
    }

    let currentData = data[this.lastDate]
    const color = this.color
    const formatCurrency = this.formatCurrency

    const margin = ({top: 20, right: 20, bottom: 0, left: 10})
    const height = (this.keys.length * 36) + margin.top + margin.bottom

    const svg = this.svg("barChart", height)

    const x = d3.scaleLinear()
      .domain([0, d3.max(currentData, d => d.value)])
      .range([margin.left, this.width - margin.right])

    const y = d3.scaleBand()
      .domain(d3.range(nonZeroAccounts[this.lastDate] + 1))
      .range([margin.top, bottomRange(this.lastDate)])
      .padding(0.1)

    const xAxis = g => g
      .attr("transform", `translate(0, ${margin.top})`)
      .call(d3.axisTop(x)
      .ticks(this.width > 400 ? 10 : 6, ".3~s")
      .tickSize(-(height - margin.top - margin.bottom)))
      .call(g => g.selectAll(".tick:not(:first-of-type) line")
        .attr("stroke-opacity", 0.3)
        .attr("stroke-dasharray", "2,2"))
      .call(g => g.select(".domain").attr("stroke-opacity", 0))

    function bars(svg) {
      let bar = svg.append("g")
        .attr("class", "color-container")
        .selectAll("a")

      return (datum, transition) => bar = bar
        .data(datum, d => d.account)
        .join(
          enter => {
            let root = enter.append("a")
              .attr("xlink:href", d => d.url)
            root.append("rect")
              .attr("fill", d => color(d.id))
              .attr("x", x(0))
              .attr("y", d => y(d.rank))
              .attr("width", d => x(d.value) - x(0))
              .attr("height", y.bandwidth())
            return root
          },
          update => {
            update.select("rect")
            .transition(transition)
            .attr("y", d => y(d.rank))
            .attr("width", d => x(d.value) - x(0))
            .attr("height", y.bandwidth())
            return update
          },
          exit => exit.transition(transition).remove()
        )
    }

    function labels(svg) {
      let label = svg.append("g")
        .attr("class", "barchart-text")
        .attr("text-anchor", "end")
        .selectAll("a")

      return (datum, transition) => {
        const labelText = (d) => {
          return `<tspan dy="-0.15em" dx="0.4em" x="0" y="0">${d.account}</tspan>
                  <tspan class="money" dy="0.85em" dx="0" x="0" y="0">${formatCurrency(d)}</tspan>`
        }

        const labelTransform = (d) => {
          const xOffset = d3.max([x(d.value) - 10, margin.left + 100])
          const yOffset = y(d.rank) + y.bandwidth() / 2
          return `translate(${xOffset}, ${yOffset})`
        }

        label = label
          .data(datum, d => d.account)
          .join(
            enter => {
              let root = enter.append("a")
                .attr("xlink:href", d => d.url)
              root.append("text")
                .attr("transform", labelTransform)
                .html(labelText)
              return root
            },
            update => {
              update.select("text")
                .transition(transition)
                .attr("transform", labelTransform)
                .select("tspan.money").text(formatCurrency)
              return update
            },
            exit => exit.transition(transition).remove()
          )
      }
    }

    const updateBars = bars(svg)
    const updateLabels = labels(svg)
    const gx = svg.append("g").attr("class", "axis").call(xAxis).attr("font-family", null)

    updateBars(currentData)
    updateLabels(currentData)

    return Object.assign(svg.node(), {
      update(index) {
        currentData = data[index]
        const t = svg.transition().duration(400).ease(d3.easeLinear)

        x.domain([0, d3.max(currentData, d => d.value)])
        y.domain(d3.range(nonZeroAccounts[index] + 1)).range([margin.top, bottomRange(index)])

        updateBars(currentData, t)
        updateLabels(currentData, t)
        gx.transition(t).call(xAxis)
      }
    })
  }

  stackedAreaChart() {
    const margin = this.margin
    const svg = this.svg("stackedAreaChart", this.height)

    const formatCurrency = this.formatCurrency

    const x = this.x
    const y = d3.scaleLinear()
      .domain([0, d3.max(this.series, d => d3.max(d, d => d[1]))]).nice()
      .range([this.height - margin.bottom, margin.top])

    const xAxis = (g) => g
      .attr("transform", `translate(0,${this.height - margin.bottom})`)
      .call(d3.axisBottom(x).ticks(this.width / 80).tickSizeOuter(0))

    const yAxis = (g) => g
      .attr("transform", `translate(${margin.left},0)`)
      .call(d3.axisLeft(y)
        .tickFormat(d3.format(".3~s"))
        .tickSize(-(this.width-margin.left-margin.right)))
      .call(g => g.selectAll(".tick:not(:first-of-type) line")
        .attr("stroke-opacity", 0.3)
        .attr("stroke-dasharray", "2,2"))
      .call(g => g.select(".domain").attr("stroke-opacity", 0))

    const area = d3.area()
      .curve(d3.curveLinear)
      .x(d => x(d.data.date))
      .y0(d => y(d[0]))
      .y1(d => y(d[1]))

    svg.append("g")
      .selectAll("path")
      .data(this.series)
      .join("path")
        .attr("fill", ({key}) => this.color(key))
        .attr("class", "color-container")
        .attr("d", area)

    svg.append("g").attr("class", "axis").call(xAxis).attr("font-family", null)
    svg.append("g").attr("class", "axis").call(yAxis).attr("font-family", null)

    const datum = this.totals[this.lastDate]
    const dateSnap = x(datum.date)

    svg.append('rect')
      .attr('fill', 'transparent')
      .attr('x', 0).attr('y', 0)
      .attr('width', this.width).attr('height', this.height)

    const textHolder = svg.append("text")
      .attr("class", "current-data")
      .attr("text-anchor", "start")
      .attr("y", 0)

    textHolder.append("tspan")
      .attr("dy", "1em")
      .attr("x", margin.left + 10)
      .text("Saldo Total")

    const currentAmount = textHolder.append("tspan")
      .style("font-size", "2em")
      .style("font-weight", "900")
      .attr("dy", "0.9em")
      .attr("x", margin.left + 10)
      .text(formatCurrency(datum))

    const hoverLine = svg.append("line")
      .classed('hover-line', true)
      .attr('x1', dateSnap).attr('x2', dateSnap)
      .attr('y1', margin.top - 4)
      .attr('y2', this.height - margin.bottom)

    const hoverDot = svg.append("circle")
      .classed('hover-dot', true)
      .attr('cx', dateSnap)
      .attr('cy', y(datum.value))
      .attr('r', 3)

    svg.on("touchmove mousemove", (event) => {
      this.updateCharts(event)
    })

    return Object.assign(svg.node(), {
      update(datum) {
        const dateSnap = x(datum.date)

        hoverLine.attr('x1', dateSnap).attr('x2', dateSnap)
        hoverDot.attr('cx', dateSnap).attr("cy", y(datum.value))
        currentAmount.text(formatCurrency(datum))
      }
    })
  }

  updateCharts(event) {
    if (!this.navBar.shouldFollow()) { return }

    const bisector = d3.bisector(d => d.date).left
    const mouseX = d3.pointer(event, this.container)[0]
    const realX = mouseX > (this.width - this.margin.right) ? this.width - this.margin.right : mouseX
    const date = this.x.invert(realX)
    const i = bisector(this.totals, date, 1)
    const a = this.totals[i - 1], b = this.totals[i]
    const datum = (date - a.date > b.date - date) ? b : a
    const index = datum === a ? i - 1 : i

    this.navBar.update(datum)
    this.stackedAreaChart.update(datum)
    this.barChart.update(index)
  }

  svg(id, height) {
    return d3.select(this.container).append("svg")
      .attr("id", id)
      .attr("viewBox", [0, 0, this.width, height])
      .attr("height", height)
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
}

export { InvestmentChart }
