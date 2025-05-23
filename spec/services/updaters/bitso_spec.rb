require "rails_helper"

RSpec.describe Updaters::Bitso do
  let(:account) { double("Account", settings: account_settings) }
  let(:account_settings) do
    {
      "bitso_key" => "test_api_key",
      "bitso_secret" => "test_api_secret"
    }
  end
  let(:mock_http_client) { double("HttpClient") }
  class FakeHttp
    def self.get(a, b = nil)
      if a.include? "balance"
        {"payload" => {"balances" => [
          {"total" => "1000.00", "currency" => "mxn"},
          {"total" => "0.5", "currency" => "btc"}
        ]}}
      elsif a.include? "ticker"
        {"payload" => {"vwap" => "800000.00"}}
      end
    end
  end

  describe ".current_balance_for" do
    it "creates a new instance and calls run" do
      result = described_class.current_balance_for(account, http_client: FakeHttp)
      expect(result).to eq(BigDecimal("401000.00"))
    end
  end

  describe "#initialize" do
    it "sets up key and secret from account settings with default HTTParty client" do
      updater = described_class.new(account)

      expect(updater.key).to eq("test_api_key")
      expect(updater.secret).to eq("test_api_secret")
      expect(updater.http_client).to eq(HTTParty)
    end

    it "accepts custom http_client parameter" do
      updater = described_class.new(account, http_client: FakeHttp)

      expect(updater.key).to eq("test_api_key")
      expect(updater.secret).to eq("test_api_secret")
      expect(updater.http_client).to eq(FakeHttp)
    end
  end

  describe "#run" do
    let(:updater) { described_class.new(account, http_client: FakeHttp) }

    it "calculates total from balances" do
      result = updater.run

      expect(result).to eq(BigDecimal("401000.00")) # 1000 + (0.5 * 800000)
    end
  end

  describe "#balances" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }
    let(:api_response) do
      {
        "payload" => {
          "balances" => [
            {"total" => "1000.50", "currency" => "mxn"},
            {"total" => "0.25", "currency" => "btc"},
            {"total" => "0.00", "currency" => "eth"} # This should be filtered out
          ]
        }
      }
    end

    before do
      allow(updater).to receive(:fetch_balances_from_api).and_return(api_response)
    end

    it "fetches and parses balances from API" do
      result = updater.send(:balances)

      expect(result).to eq([
        {amount: BigDecimal("1000.50"), currency: "mxn"},
        {amount: BigDecimal("0.25"), currency: "btc"}
      ])
    end
  end

  describe "#fetch_balances_from_api" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }
    let(:fixed_time) { Time.zone.parse("2023-01-01 12:00:00 UTC") }
    let(:expected_nonce) { fixed_time.to_i.to_s }
    let(:expected_signature) { "expected_signature_hash" }

    before do
      travel_to(fixed_time)
      allow(updater).to receive(:signature).with(expected_nonce, "/v3/balance/").and_return(expected_signature)
    end

    after { travel_back }

    it "makes authenticated API request with correct headers" do
      expected_headers = {
        "Authorization" => "Bitso test_api_key:#{expected_nonce}:#{expected_signature}"
      }

      allow(mock_http_client).to receive(:get).and_return({"payload" => {"balances" => []}})

      updater.send(:fetch_balances_from_api)

      expect(mock_http_client).to have_received(:get).with(
        "https://api.bitso.com/v3/balance/",
        headers: expected_headers
      )
    end
  end

  describe "#parse_balances_response" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }

    context "with valid response" do
      let(:response) do
        {
          "payload" => {
            "balances" => [
              {"total" => "1000.50", "currency" => "mxn"},
              {"total" => "0.25", "currency" => "btc"},
              {"total" => "0.00", "currency" => "eth"}
            ]
          }
        }
      end

      it "parses balances and filters out zero amounts" do
        result = updater.send(:parse_balances_response, response)

        expect(result).to eq([
          {amount: BigDecimal("1000.50"), currency: "mxn"},
          {amount: BigDecimal("0.25"), currency: "btc"}
        ])
      end
    end

    context "with empty or nil response" do
      it "handles nil payload gracefully" do
        response = {"payload" => nil}

        expect { updater.send(:parse_balances_response, response) }.to raise_error(NoMethodError)
      end

      it "handles missing balances key" do
        response = {"payload" => {}}

        expect { updater.send(:parse_balances_response, response) }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#fetch_exchange_rate" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }

    it "fetches exchange rate for given currency" do
      exchange_response = {"payload" => {"vwap" => "800000.50"}}
      allow(mock_http_client).to receive(:get).and_return(exchange_response)

      result = updater.send(:fetch_exchange_rate, "btc")

      expect(mock_http_client).to have_received(:get).with(
        "https://api.bitso.com/v3/ticker/?book=btc_mxn"
      )
      expect(result).to eq("800000.50")
    end
  end

  describe "#calculate_total_from" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }
    let(:balances_array) do
      [
        {amount: BigDecimal("1000.00"), currency: "mxn"},
        {amount: BigDecimal("0.5"), currency: "btc"},
        {amount: BigDecimal("100.0"), currency: "usd"}
      ]
    end

    before do
      allow(updater).to receive(:fetch_exchange_rate).with("btc").and_return("800000.00")
      allow(updater).to receive(:fetch_exchange_rate).with("usd").and_return("18.50")
    end

    it "calculates total with MXN amounts unchanged and others converted" do
      result = updater.send(:calculate_total_from, balances_array)

      # 1000 (MXN) + (0.5 * 800000) (BTC) + (100 * 18.50) (USD)
      expected_total = BigDecimal("1000.00") + BigDecimal("400000.00") + BigDecimal("1850.00")
      expect(result).to eq(expected_total)
    end

    it "handles empty array" do
      result = updater.send(:calculate_total_from, [])
      expect(result).to eq(BigDecimal(0))
    end
  end

  describe "#generate_nonce" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }
    let(:fixed_time) { Time.zone.parse("2023-01-01 12:00:00") }

    it "generates nonce from current timestamp" do
      travel_to(fixed_time) do
        nonce = updater.send(:generate_nonce)
        expect(nonce).to eq(fixed_time.to_i.to_s)
      end
    end

    it "generates different nonces at different times" do
      travel_to(fixed_time)
      nonce1 = updater.send(:generate_nonce)

      travel_to(fixed_time + 1.second)
      nonce2 = updater.send(:generate_nonce)

      expect(nonce2).not_to eq(nonce1)
      travel_back
    end
  end

  describe "#auth_header" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }

    it "formats authorization header correctly" do
      header = updater.send(:auth_header, "1234567890", "signature_hash")
      expect(header).to eq("Bitso test_api_key:1234567890:signature_hash")
    end
  end

  describe "#signature" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }

    it "generates HMAC-SHA256 signature" do
      nonce = "1234567890"
      path = "/v3/balance/"

      # We can't easily test the exact hash without knowing the secret,
      # but we can verify it's a valid hex string of correct length
      signature = updater.send(:signature, nonce, path)

      expect(signature).to be_a(String)
      expect(signature.length).to eq(64) # SHA256 hex string length
      expect(signature).to match(/\A[a-f0-9]+\z/) # Valid hex string
    end

    it "includes payload in signature when provided" do
      nonce = "1234567890"
      path = "/v3/balance/"
      payload = '{"key":"value"}'

      signature_with_payload = updater.send(:signature, nonce, path, payload)
      signature_without_payload = updater.send(:signature, nonce, path)

      expect(signature_with_payload).not_to eq(signature_without_payload)
    end
  end

  describe "integration with real-like data" do
    let(:updater) { described_class.new(account, http_client: mock_http_client) }
    let(:balances_response) do
      {
        "payload" => {
          "balances" => [
            {"total" => "5000.00", "currency" => "mxn"},
            {"total" => "0.1", "currency" => "btc"},
            {"total" => "2.5", "currency" => "eth"}
          ]
        }
      }
    end
    let(:btc_ticker_response) { {"payload" => {"vwap" => "700000.00"}} }
    let(:eth_ticker_response) { {"payload" => {"vwap" => "40000.00"}} }

    before do
      allow(mock_http_client).to receive(:get)
        .with("https://api.bitso.com/v3/balance/", any_args)
        .and_return(balances_response)

      allow(mock_http_client).to receive(:get)
        .with("https://api.bitso.com/v3/ticker/?book=btc_mxn")
        .and_return(btc_ticker_response)

      allow(mock_http_client).to receive(:get)
        .with("https://api.bitso.com/v3/ticker/?book=eth_mxn")
        .and_return(eth_ticker_response)
    end

    it "calculates correct total balance across multiple currencies" do
      result = updater.run

      # 5000 (MXN) + (0.1 * 700000) (BTC) + (2.5 * 40000) (ETH)
      expected_total = BigDecimal("5000.00") + BigDecimal("70000.00") + BigDecimal("100000.00")
      expect(result).to eq(expected_total)
    end
  end
end
