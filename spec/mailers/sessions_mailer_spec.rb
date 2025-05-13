# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsMailer, type: :mailer do
  fixtures :users

  let(:user) { users(:test_user) }
  let(:token) { "sample_token_123" }

  describe "#login" do
    let(:mail) { described_class.login(user: user, token: token) }

    it "renders the headers" do
      expect(mail.subject).to eq("Entrar a Dineritos")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["noreply@dineritos.mx"])
    end

    it "renders the body with login link" do
      expect(mail.body.encoded).to include("Entrar a dineritos")
      expect(mail.body.encoded).to include(token)
    end

    it "includes the login URL in text format" do
      expect(mail.text_part.body.encoded).to include("Entra a la siguiente liga para iniciar sesión")
      expect(mail.text_part.body.encoded).to include(token)
    end
  end
end
