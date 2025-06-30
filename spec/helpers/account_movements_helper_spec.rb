require "rails_helper"

RSpec.describe AccountMovementsHelper, type: :helper do
  let(:account) { double("Account", id: 1) }
  let(:report) { double("Report", account: account) }

  before do
    helper.instance_variable_set(:@report, report)
    helper.instance_variable_set(:@account, account)

    # Stub path helpers
    allow(helper).to receive(:account_movements_path) do |*args|
      acc = args[0] || account
      params = args[1] || {}
      "/accounts/#{acc.id}/movements?#{params.to_query}"
    end
    allow(helper).to receive(:account_path) { |acc| "/accounts/#{acc.id}" }
    allow(helper).to receive(:account_statistics_path) { |acc| "/accounts/#{acc.id}/statistics" }
    allow(helper).to receive(:edit_account_path) { |acc| "/accounts/#{acc.id}/edit" }
    allow(helper).to receive(:l) { |date, format:| date.strftime("%Y-%m") }
  end

  describe "#prev_month_link" do
    context "when prev_month exists" do
      let(:prev_date) { Date.new(2023, 1, 1) }

      before do
        allow(report).to receive(:prev_month).and_return(prev_date)
      end

      it "returns a link to the previous month" do
        html = helper.prev_month_link
        expect(html).to include('href="/accounts/1/movements?month=2023-01"')
        expect(html).to include("Anterior")
      end
    end

    context "when prev_month is nil" do
      before do
        allow(report).to receive(:prev_month).and_return(nil)
      end

      it "returns a span with title" do
        html = helper.prev_month_link
        expect(html).to include("<span>Anterior</span>")
        expect(html).not_to include("<a")
      end
    end
  end

  describe "#next_month_link" do
    context "when next_month exists" do
      let(:next_date) { Date.new(2023, 3, 1) }

      before do
        allow(report).to receive(:next_month).and_return(next_date)
      end

      it "returns a link to the next month" do
        html = helper.next_month_link
        expect(html).to include('href="/accounts/1/movements?month=2023-03"')
        expect(html).to include("Siguiente")
      end
    end

    context "when next_month is nil" do
      before do
        allow(report).to receive(:next_month).and_return(nil)
      end

      it "returns a span with title" do
        html = helper.next_month_link
        expect(html).to include("<span>Siguiente</span>")
        expect(html).not_to include("<a")
      end
    end
  end

  describe "#month_link" do
    let(:date) { Date.new(2023, 2, 1) }

    context "when date is present" do
      it "returns a link with formatted date" do
        html = helper.month_link(date, "Test Title")
        expect(html).to include('href="/accounts/1/movements?month=2023-02"')
        expect(html).to include("Test Title")
      end
    end

    context "when date is nil" do
      it "returns a span with title" do
        html = helper.month_link(nil, "Test Title")
        expect(html).to include("<span>Test Title</span>")
        expect(html).not_to include("<a")
      end
    end
  end

  describe "#account_main_nav" do
    context "when account is new and empty" do
      before do
        allow(account).to receive(:new_and_empty?).and_return(true)
      end

      it "returns simplified navigation" do
        html = helper.account_main_nav(current: "Resumen")
        expect(html).to include('data-account-header-target="nav"')
        expect(html).to include("Resumen")
        expect(html).to include("Opciones")
        expect(html).not_to include("Detalle")
        expect(html).not_to include("Estadísticas")
      end

      it "marks current page as active" do
        html = helper.account_main_nav(current: "Opciones")
        expect(html).to include('class="active"')
      end
    end

    context "when account is not new and empty" do
      before do
        allow(account).to receive(:new_and_empty?).and_return(false)
        allow(helper).to receive(:existing_account_nav).and_return("<nav>existing</nav>".html_safe)
      end

      it "returns existing account navigation" do
        html = helper.account_main_nav(current: "Resumen")
        expect(html).to include("existing")
      end
    end
  end

  describe "#existing_account_nav" do
    it "returns full navigation menu" do
      html = helper.existing_account_nav(current: "Resumen")
      expect(html).to include('data-account-header-target="nav"')
      expect(html).to include("Resumen")
      expect(html).to include("Detalle")
      expect(html).to include("Estadísticas")
      expect(html).to include("Opciones")
    end

    it "marks current page as active" do
      html = helper.existing_account_nav(current: "Detalle")
      expect(html).to include('class="active"')
    end
  end

  describe "#account_nav_link" do
    it "returns list item with link" do
      html = helper.account_nav_link("Test", "account_path", "Other")
      expect(html).to include('<li data-account-header-target="link">')
      expect(html).to include('href="/accounts/1"')
      expect(html).to include("Test")
      expect(html).not_to include('class="active"')
    end

    it "adds active class when current matches title" do
      html = helper.account_nav_link("Test", "account_path", "Test")
      expect(html).to include('class="active"')
    end
  end
end
