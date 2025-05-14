require "rails_helper"

RSpec.describe Investments::SummariesController, type: :request do
  fixtures :users
  let(:user) { users(:test_user) }

  describe "GET #show" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get investments_summary_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      before do
        allow_any_instance_of(Investments::SummariesController)
          .to receive(:current_user).and_return(user)
        get investments_summary_path
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "returns HTML content" do
        expect(response.content_type).to include("text/html")
      end

      it "renders the investment summary partial" do
        expect(response.body).to include('<dl class="investment-summary">')
      end
    end
  end
end
