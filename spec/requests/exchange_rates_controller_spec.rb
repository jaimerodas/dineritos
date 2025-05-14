require "rails_helper"

RSpec.describe ExchangeRatesController, type: :request do
  fixtures :users

  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get exchange_rate_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      before do
        allow_any_instance_of(ExchangeRatesController)
          .to receive(:current_user).and_return(user)
      end

      it "returns a successful HTML response" do
        get exchange_rate_path
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end
    end
  end
end
