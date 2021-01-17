class ErrorsMailer < ApplicationMailer
  def generic(error, title: "")
    @error = error
    user = User.first
    mail to: user.email, subject: "Error: #{title}"
  end
end
