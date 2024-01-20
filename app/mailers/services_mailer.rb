class ServicesMailer < ApplicationMailer
  helper MoneyHelper

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.services_mailer.daily_update.subject
  #
  def daily_update(user, errors: [])
    @report = EarningsReport.for(user)
    @errors = errors
    mail to: user.email, subject: "Actualización de Saldos #{Date.current}"
  end

  def new_daily_update(user, date: Date.current, errors: [])
    @report = DailyReport.for(user, date, errors)
    mail to: user.email, subject: "Reporte diario: #{@report.date}"
  end
end
