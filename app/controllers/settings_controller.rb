class SettingsController < ApplicationController
  before_action :auth

  def show
    @passkeys = current_user.passkeys.all
    @settings = current_user.settings
  end

  def create
    current_user.update(settings: settings_to_b)
    redirect_to settings_path, notice: t("settings.saved_successfully")
  end

  private

  def settings_to_b
    settings_params.to_h.map { |name, value| [name, value == "1"] }.to_h
  end

  def settings_params
    params.require(:settings).permit(:daily_email, :send_email_after_update)
  end
end
