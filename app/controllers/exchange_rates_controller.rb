class ExchangeRatesController < ApplicationController
  before_action :auth

  # GET /tipo_de_cambio
  # Renders the HTML page; the JS chart fetches data from /graficas/tipo_de_cambio.json
  def show
    # no-op: view will instantiate the Stimulus controller and fetch JSON
  end
end
