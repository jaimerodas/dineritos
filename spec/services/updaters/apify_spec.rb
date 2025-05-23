require "rails_helper"

RSpec.describe Updaters::Apify do
  let(:account) { double("Account", settings: account_settings) }
  let(:account_settings) do
    {
      "username" => "test_username",
      "password" => "test_password",
      "actor" => "test_actor",
      "token" => "test_token"
    }
  end

  describe ".current_balance_for" do
    it "creates a new instance and calls it" do
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).with(account).and_return(instance)
      allow(instance).to receive(:call).and_return(BigDecimal("1000.00"))

      result = described_class.current_balance_for(account)

      expect(described_class).to have_received(:new).with(account)
      expect(instance).to have_received(:call)
      expect(result).to eq(BigDecimal("1000.00"))
    end
  end

  describe "#initialize" do
    it "sets up params with account settings and inputs" do
      updater = described_class.new(account)

      expect(updater.params).to include(account_settings)
      expect(updater.params["inputs"]).to eq({
        username: "test_username",
        password: "test_password"
      })
    end
  end

  describe "#inputs" do
    it "returns username and password from params" do
      updater = described_class.new(account)

      expect(updater.inputs).to eq({
        username: "test_username",
        password: "test_password"
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
  end

  describe "#call" do
    let(:updater) { described_class.new(account) }
    let(:successful_run) { double("ApifyRun", succeeded?: true, value: BigDecimal("1234.56")) }
    let(:failed_run) { double("ApifyRun", succeeded?: false) }

    context "when last successful run is recent (less than 22 hours ago)" do
      before do
        allow(updater).to receive(:last_successful_run_time).and_return(1.hour.ago)
        allow(updater).to receive(:last_successful_run).and_return(successful_run)
      end

      it "uses the last successful run" do
        result = updater.call

        expect(result).to eq(BigDecimal("1234.56"))
      end
    end

    context "when last successful run is old (more than 22 hours ago)" do
      before do
        allow(updater).to receive(:last_successful_run_time).and_return(25.hours.ago)
        allow(updater).to receive(:start_run).and_return(successful_run)
      end

      it "starts a new run" do
        result = updater.call

        expect(result).to eq(BigDecimal("1234.56"))
      end
    end

    context "when run doesn't succeed immediately" do
      let(:eventually_successful_run) do
        double("ApifyRun").tap do |run|
          call_count = 0
          allow(run).to receive(:succeeded?) do
            call_count += 1
            call_count >= 3 # Succeeds on third call
          end
          allow(run).to receive(:value).and_return(BigDecimal("500.00"))
          allow(run).to receive(:refresh!)
        end
      end

      before do
        allow(updater).to receive(:last_successful_run_time).and_return(1.hour.ago)
        allow(updater).to receive(:last_successful_run).and_return(eventually_successful_run)
        allow(updater).to receive(:sleep) # Don't actually sleep in tests
      end

      it "retries and refreshes until success" do
        result = updater.call

        expect(eventually_successful_run).to have_received(:refresh!).at_least(2).times
        expect(result).to eq(BigDecimal("500.00"))
      end
    end

    context "when run never succeeds" do
      before do
        allow(updater).to receive(:last_successful_run_time).and_return(1.hour.ago)
        allow(updater).to receive(:last_successful_run).and_return(failed_run)
        allow(failed_run).to receive(:refresh!)
        allow(updater).to receive(:sleep) # Don't actually sleep in tests
      end

      it "raises an error after 10 attempts" do
        expect { updater.call }.to raise_error(RuntimeError)
        expect(failed_run).to have_received(:refresh!).exactly(10).times # 10 refresh calls
      end
    end
  end

  describe "private methods" do
    let(:updater) { described_class.new(account) }
    let(:fixed_time) { Time.current - 2.hours }
    let(:mock_last_run) { double("ApifyRun", finished_at: fixed_time) }

    describe "#last_successful_run_time" do
      before do
        allow(updater).to receive(:last_successful_run).and_return(mock_last_run)
      end

      it "returns the finished_at time of the last successful run" do
        expect(updater.send(:last_successful_run_time)).to eq(fixed_time)
      end
    end

    describe "#last_successful_run" do
      it "memoizes the ApifyRun.last_successful call" do
        allow(Updaters::ApifyRun).to receive(:last_successful).with(updater.params).and_return(mock_last_run)

        # Call twice to test memoization
        result1 = updater.send(:last_successful_run)
        result2 = updater.send(:last_successful_run)

        expect(Updaters::ApifyRun).to have_received(:last_successful).once
        expect(result1).to eq(mock_last_run)
        expect(result2).to eq(mock_last_run)
      end
    end

    describe "#start_run" do
      it "memoizes the ApifyRun.new call" do
        mock_run = double("ApifyRun")
        allow(Updaters::ApifyRun).to receive(:new).with(updater.params).and_return(mock_run)

        # Call twice to test memoization
        result1 = updater.send(:start_run)
        result2 = updater.send(:start_run)

        expect(Updaters::ApifyRun).to have_received(:new).once
        expect(result1).to eq(mock_run)
        expect(result2).to eq(mock_run)
      end
    end
  end
end
