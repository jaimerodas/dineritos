# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServicesMailer, type: :mailer do
  fixtures :users, :accounts, :balances

  let(:user) { users(:test_user) }
  let(:date) { Date.new(2023, 3, 15) }
  let(:errors) { [{account: "Test Account", error: "TestError", message: "Test error message"}] }
  let(:actions) { [{account: accounts(:savings_account)}] }

  describe "#daily_update" do
    # Create mock report class
    let(:mock_report_class) do
      Class.new do
        def self.for(user)
          new
        end

        def details
          {
            "Savings Account" => {current: BigDecimal(5000), day: BigDecimal(100), month: BigDecimal(500)},
            "Investment Account" => {current: BigDecimal(10000), day: BigDecimal(200), month: BigDecimal(1000)}
          }
        end

        def totals
          {current: BigDecimal(15000), day: BigDecimal(300), month: BigDecimal(1500)}
        end
      end
    end

    let(:mail) { described_class.daily_update(user, errors: errors, report: mock_report_class) }

    it "renders the headers" do
      travel_to date
      expect(mail.subject).to eq("Actualización de Saldos #{Date.current}")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["noreply@dineritos.mx"]) # Actual value from ApplicationMailer
      travel_back
    end

    it "renders the body with report data" do
      expect(mail.body.encoded).to include("Savings Account")
      expect(mail.body.encoded).to include("Investment Account")
      expect(mail.body.encoded).to include("15,000")
      expect(mail.body.encoded).to include("300")
      expect(mail.body.encoded).to include("1,500")
    end

    it "includes errors when provided" do
      expect(mail.body.encoded).to include("Test Account")
      expect(mail.body.encoded).to include("TestError")
      expect(mail.body.encoded).to include("Test error message")
    end
  end

  describe "#new_daily_update" do
    # Create mock report class
    let(:mock_report_class) do
      Class.new do
        def self.for(user, date, errors)
          new
        end

        def date
          Date.new(2023, 3, 15)
        end

        def total
          BigDecimal(15000)
        end

        def todays_exchange_rate
          BigDecimal("20.5")
        end

        def day
          BigDecimal(300)
        end

        def month
          BigDecimal(1500)
        end

        def day_usd
          BigDecimal(100)
        end

        def month_usd
          BigDecimal(500)
        end

        def day_exchange_rate
          BigDecimal("20.0")
        end

        def month_exchange_rate
          BigDecimal("19.5")
        end

        def errors
          [{account: "Test Account", error: "TestError", message: "Test error message"}]
        end
      end
    end

    let(:mail) { described_class.new_daily_update(user, date: date, errors: errors, actions: actions, report: mock_report_class) }

    it "renders the headers" do
      expect(mail.subject).to eq("Reporte diario: 2023-03-15")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["noreply@dineritos.mx"])
    end

    it "renders the body with report data" do
      expect(mail.body.encoded).to include("2023-03-15")
      expect(mail.body.encoded).to include("15,000")
      expect(mail.body.encoded).to include("20.5")
      expect(mail.body.encoded).to include("300")
      expect(mail.body.encoded).to include("1,500")
    end

    it "includes exchange rate information" do
      expect(mail.body.encoded).to include("20.0")  # day_exchange_rate
      expect(mail.body.encoded).to include("19.5")  # month_exchange_rate
      expect(mail.body.encoded).to include("100")   # day_usd
      expect(mail.body.encoded).to include("500")   # month_usd
    end

    it "includes errors when provided" do
      expect(mail.body.encoded).to include("Test Account")
      expect(mail.body.encoded).to include("TestError")
      expect(mail.body.encoded).to include("Test error message")
    end

    it "includes actions when provided" do
      expect(mail.body.encoded).to include("Savings Account")
      expect(mail.body.encoded).to include("0 como saldo. Quieres")
    end
  end
end
