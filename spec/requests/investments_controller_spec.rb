require "rails_helper"

RSpec.describe InvestmentsController, type: :request do
  fixtures :users
  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get root_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }
      before { get root_path }

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "returns HTML content" do
        expect(response.content_type).to include("text/html")
      end

      it "includes the investments Stimulus controller attribute" do
        expect(response.body).to include('data-controller="investments"')
      end
    end

    context "with an explicit period" do
      stub_current_user { user }

      it "passes it through instead of the default" do
        allow(InvestmentSummary).to receive(:for).and_call_original
        get root_path, params: {period: "past_month"}
        expect(response).to have_http_status(:success)
        expect(InvestmentSummary).to have_received(:for)
          .with(user: user, period: "past_month")
      end
    end
  end
end
