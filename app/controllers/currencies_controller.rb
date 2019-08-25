class CurrenciesController < ApplicationController
  before_action :auth

  def show
    @currencyRate = CurrencyRate.find_or_create_by(
      date: currency_params[:date],
      currency: currency_params[:currency]
    )
  end

  private

  def currency_params
    params.permit("date", "currency")
  end
end
