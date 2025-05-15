require "rails_helper"

RSpec.describe AccountBalancesController, type: :request do
  fixtures :users, :accounts, :balances

  let(:user) { users(:test_user) }
  let(:account) { accounts(:savings_account) }
  let(:balance) { balances(:savings_jan1) }

  describe "#new" do
    context "when user is logged in" do
      stub_current_user { user }
      before { travel_to Date.new(2023, 1, 1) }

      after { travel_back }

      it "returns a successful response" do
        get new_account_account_balance_path(account)
        expect(response).to have_http_status(:success)
      end

      it "returns HTML content" do
        get new_account_account_balance_path(account)
        expect(response.content_type).to include("text/html")
      end
    end

    context "when user is not logged in" do
      it "redirects to login page" do
        get new_account_account_balance_path(account)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "#create" do
    stub_current_user { user }
    before { travel_to Date.new(2023, 1, 1) }

    after { travel_back }

    context "with valid parameters" do
      it "creates or updates the balance and redirects to movements path" do
        post account_account_balances_path(account), params: {balance: {amount: "6000", transfers: "100"}}
        expect(response).to redirect_to(account_movements_path(account))
        new_balance = Balance.find_by(account: account, date: Date.new(2023, 1, 1))
        expect(new_balance.amount_cents).to eq(6000 * 100)
        expect(new_balance.transfers_cents).to eq(100 * 100)
      end
    end

    context "with invalid parameters" do
      it "renders the new template" do
        post account_account_balances_path(account), params: {balance: {amount: "", transfers: ""}}
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
      end
    end
  end

  describe "#edit" do
    context "when user is logged in" do
      stub_current_user { user }

      it "returns a successful response" do
        get edit_account_balance_path(balance)
        expect(response).to have_http_status(:success)
      end

      it "returns HTML content" do
        get edit_account_balance_path(balance)
        expect(response.content_type).to include("text/html")
      end
    end

    context "when user is not logged in" do
      it "redirects to login page" do
        get edit_account_balance_path(balance)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "#update" do
    let(:update_params) { {balance: {amount: "7000", transfers: "200"}} }

    context "when user is logged in" do
      stub_current_user { user }

      context "when the update is successful" do
        before do
          allow(UpdateBalance).to receive(:run).and_return(true)
        end

        it "redirects to movements path for the balance's account and month" do
          patch account_balance_path(balance), params: update_params
          expect(response).to redirect_to(
            account_movements_path(balance.account, month: balance.date.strftime("%Y-%m"))
          )
        end
      end

      context "when the update fails" do
        before do
          allow(UpdateBalance).to receive(:run).and_return(false)
        end

        it "renders the edit template" do
          patch account_balance_path(balance), params: update_params
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/html")
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login page" do
        patch account_balance_path(balance), params: update_params
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
