require "rails_helper"

RSpec.describe Updaters::Afluenta do
  let(:account) { double("Account", settings: account_settings) }
  let(:account_settings) do
    {
      "username" => "test_username",
      "password" => "test_password",
      "secret" => "test_otp_secret",
      "actor" => "test_actor",
      "token" => "test_token"
    }
  end

  describe "#inputs" do
    it "returns the correct inputs hash" do
      updater = described_class.new(account)

      expect(updater.inputs).to eq({
        username: "test_username",
        password: "test_password",
        otp_secret: "test_otp_secret"
      })
    end

    it "raises an error when username is missing" do
      account_settings.delete("username")

      expect { described_class.new(account).inputs }.to raise_error(KeyError)
    end

    it "raises an error when password is missing" do
      account_settings.delete("password")

      expect { described_class.new(account).inputs }.to raise_error(KeyError)
    end

    it "raises an error when secret is missing" do
      account_settings.delete("secret")

      expect { described_class.new(account).inputs }.to raise_error(KeyError)
    end
  end

  describe ".current_balance_for" do
    let(:fake_http_handler) { double("HTTPHandler") }
    let(:successful_response) do
      {
        "data" => {
          "status" => "SUCCEEDED",
          "finishedAt" => 1.hour.ago.iso8601,
          "defaultDatasetId" => "dataset123"
        }
      }
    end
    let(:balance_response) { [{"value" => "1,234.56"}] }

    before do
      allow(fake_http_handler).to receive(:get).and_return(successful_response, balance_response)
      allow(Updaters::ApifyRun).to receive(:last_successful).and_return(
        double("ApifyRun", succeeded?: true, value: BigDecimal("1234.56"))
      )
    end

    it "returns the current balance" do
      allow_any_instance_of(described_class).to receive(:last_successful_run_time).and_return(1.hour.ago)

      result = described_class.current_balance_for(account)

      expect(result).to eq(BigDecimal("1234.56"))
    end
  end

  describe "inheritance from Updaters::Apify" do
    it "inherits from Updaters::Apify" do
      expect(described_class.superclass).to eq(Updaters::Apify)
    end

    it "overrides the inputs method to include otp_secret" do
      updater = described_class.new(account)
      parent_inputs = Updaters::Apify.new(account).inputs
      afluenta_inputs = updater.inputs

      expect(afluenta_inputs.keys).to include(:otp_secret)
      expect(parent_inputs.keys).not_to include(:otp_secret)
      expect(afluenta_inputs[:username]).to eq(parent_inputs[:username])
      expect(afluenta_inputs[:password]).to eq(parent_inputs[:password])
    end
  end
end
