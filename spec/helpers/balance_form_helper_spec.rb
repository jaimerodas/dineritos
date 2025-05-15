require "rails_helper"
require "ostruct"

RSpec.describe BalanceFormHelper, type: :helper do
  describe "#amount_field" do
    let(:container) { double("FormBuilder") }

    before do
      allow(container).to receive(:label) do |_method, name|
        "<label>#{name}</label>".html_safe
      end
      allow(container).to receive(:number_field).and_return("<input/>".html_safe)
    end

    context "when currency is MXN and no date" do
      let(:account) { OpenStruct.new(id: 1, amount: nil, currency: "MXN", name: "MX Account", date: nil) }

      it "renders only label and input inside field div" do
        html = helper.amount_field(container, account)
        expect(html).to include('class="field"')
        expect(html).to include("<label>MX Account</label>")
        expect(html).to include("<input/>")
        expect(html).not_to include('class="input-field"')
        expect(html).not_to include("<span>")
        expect(html).not_to include("Última actualización:")
      end
    end

    context "when currency is non-MXN and with date" do
      let(:account) { OpenStruct.new(id: 2, amount: 100.0, currency: "USD", name: "USD Account", date: "2023-01-01") }

      it "renders label, input and currency span inside input-field, and help text" do
        html = helper.amount_field(container, account)
        expect(html).to include('class="field"')
        expect(html).to include("<label>USD Account</label>")
        expect(html).to include('class="input-field"')
        expect(html).to include("<input/>")
        expect(html).to include("<span>USD</span>")
        expect(html).to include("Última actualización: 2023-01-01")
        expect(html).to include('class="form-help"')
      end
    end
  end

  describe "#self_updating_notice" do
    before do
      helper.instance_variable_set(:@data, double("data", non_editable_accounts: non_editable_accounts))
    end

    context "when there are no non-editable accounts" do
      let(:non_editable_accounts) { [] }

      it "returns nil" do
        expect(helper.self_updating_notice).to be_nil
      end
    end

    context "when there is one non-editable account" do
      let(:non_editable_accounts) { ["Checking"] }

      it "renders a singular notice" do
        html = helper.self_updating_notice
        expect(html).to include("<p>")
        expect(html).to include("La cuenta ")
        expect(html).to include("<b>Checking</b>")
        expect(html).to include("actualiza sola.")
      end
    end

    context "when there are multiple non-editable accounts" do
      let(:non_editable_accounts) { ["Checking", "Savings"] }

      it "renders a plural notice" do
        html = helper.self_updating_notice
        expect(html).to include("Las cuentas ")
        expect(html).to include("<b>Checking, Savings</b>")
        expect(html).to include("actualizan solas.")
      end
    end
  end
end
