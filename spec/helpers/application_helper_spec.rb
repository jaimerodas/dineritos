require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#prev_link" do
    it "returns nil when link is nil" do
      expect(helper.prev_link(nil)).to be_nil
    end

    context "when link is present" do
      before do
        # Define a stub path helper for testing
        helper.define_singleton_method(:balance_path) { |page| "/balances?page=#{page}" }
      end

      it "returns a link with correct href, class, and svg content" do
        html = helper.prev_link(2)
        expect(html).to include('href="/balances?page=2"')
        expect(html).to include('class="previous_page"')
        expect(html).to include("<svg")
      end
    end
  end

  describe "#next_link" do
    it "returns nil when link is nil" do
      expect(helper.next_link(nil)).to be_nil
    end

    context "when link is present" do
      before do
        helper.define_singleton_method(:balance_path) { |page| "/balances?page=#{page}" }
      end

      it "returns a link with correct href, class, and svg content" do
        html = helper.next_link(3)
        expect(html).to include('href="/balances?page=3"')
        expect(html).to include('class="next_page"')
        expect(html).to include("<svg")
      end
    end
  end

  describe "#balance_navigation" do
    it "wraps prev and next links in a navigation section" do
      # Stub prev_link and next_link to return html_safe strings
      allow(helper).to receive(:prev_link).with(1).and_return("<prev/>".html_safe)
      allow(helper).to receive(:next_link).with(5).and_return("<next/>".html_safe)
      html = helper.balance_navigation(1, 5)
      expect(html).to include('<section class="navigation"')
      expect(html).to include("<prev/>")
      expect(html).to include("<next/>")
    end
  end

  describe "#title" do
    context "when content_for(:title) is present" do
      it "appends the base title after the content_for title" do
        allow(helper).to receive(:content_for).with(:title).and_return("Page Title")
        expect(helper.title).to eq("Page Title - Dineritos")
      end
    end

    context "when content_for(:title) is blank or nil" do
      it "returns the base title only" do
        allow(helper).to receive(:content_for).with(:title).and_return(nil)
        expect(helper.title).to eq("Dineritos")
      end
    end
  end
end
