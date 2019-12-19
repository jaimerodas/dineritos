class ServicesMailer < ApplicationMailer
  helper MoneyHelper

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.services_mailer.daily_update.subject
  #
  def daily_update(summary)
    @summary = summary
    mail to: User.first.email, subject: "Actualización de Saldos #{Date.today}"
  end
end