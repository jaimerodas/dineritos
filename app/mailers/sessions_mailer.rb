class SessionsMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.sessions_mailer.login.subject
  #
  def login(user:, token:)
    @token = token
    @user = user
    mail to: user.email, subject: "Entrar a Dineritos"
  end
end
