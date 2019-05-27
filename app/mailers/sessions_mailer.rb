class SessionsMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.sessions_mailer.login.subject
  #
  def login(token:)
    @token = token
    mail to: Rails.application.credentials[:email]
  end
end
