class Charts::YieldsController < ApplicationController
  before_action :auth

  def show
    render json: IrrReport.for(user: current_user).by_month
  end
end
