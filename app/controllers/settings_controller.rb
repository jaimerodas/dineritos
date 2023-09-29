class SettingsController < ApplicationController
  before_action :auth

  def index
    @passkeys = current_user.passkeys.all
  end
end
