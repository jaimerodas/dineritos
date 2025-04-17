class Charts::ExchangeRatesController < ApplicationController
  before_action :auth

  # GET /graficas/tipo_de_cambio.json?currency=USD&period=past_year
  def show
    currency = params[:currency].presence || "USD"
    period = params[:period].presence || "past_year"

    period_range = case period
    when "past_year"
      1.year.ago.to_date..Date.current
    when "all"
      (CurrencyRate.minimum(:date) || Date.current)..Date.current
    else
      if period.to_i.to_s == period
        year = period.to_i
        Date.new(year, 1, 1)..Date.new(year, 12, 31)
      else
        1.year.ago.to_date..Date.current
      end
    end

    rates = CurrencyRate.where(currency: currency, date: period_range)
      .order(:date)
    data = rates.map { |r| {date: r.date.iso8601, value: r.rate} }
    render json: data
  end
end
