class MissingBalancesController < ApplicationController
  before_action :auth

  def index
    @accounts = current_user.accounts.missing_todays_balance
  end
end
