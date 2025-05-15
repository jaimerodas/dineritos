require "rails_helper"

RSpec.describe AccountsController, type: :request do
  fixtures :users, :accounts

  let(:user) { users(:test_user) }
  let(:account) { accounts(:savings_account) }

  describe "GET #index" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get accounts_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }

      let(:fake_account_row) do
        double(
          name: "Stub Account",
          final_balance: 100,
          total_earnings: 10,
          total_transferred: 20,
          to_partial_path: "accounts/account"
        )
      end
      let(:fake_report) do
        double(
          accounts: [fake_account_row],
          totals: {balance: BigDecimal(100), earnings: BigDecimal(10), transfers: BigDecimal(20)}
        )
      end

      before do
        allow(AccountsComparisonReport).to receive(:new)
          .with(user: user, period: AccountsController::DEFAULT_PERIOD)
          .and_return(fake_report)
        get accounts_path
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "renders the accounts list and add link" do
        expect(response.body).to include(fake_account_row.name)
        expect(response.body).to include("Agregar")
      end
    end
  end

  describe "GET #new" do
    context "when not logged in" do
      it "redirects to login page" do
        get new_account_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }
      before { get new_account_path }

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "renders the new account form" do
        expect(response.body).to include("Agregar Cuenta")
        expect(response.body).to include("<form")
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) { {account: {name: "Test Account", currency: "MXN", platform: "no_platform"}} }
    let(:invalid_params) { {account: {name: "", currency: "", platform: ""}} }

    context "when not logged in" do
      it "redirects to login page" do
        post accounts_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }

      context "with valid parameters" do
        it "creates a new account and redirects to index" do
          expect {
            post accounts_path, params: valid_params
          }.to change { user.accounts.count }.by(1)
          expect(response).to redirect_to(accounts_path)
        end
      end

      context "with invalid parameters" do
        it "renders the new template" do
          post accounts_path, params: invalid_params
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Agregar Cuenta")
        end
      end
    end
  end

  describe "GET #edit" do
    context "when not logged in" do
      it "redirects to login page" do
        get edit_account_path(account)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }
      before { get edit_account_path(account) }

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "renders the edit form" do
        expect(response.body).to include("<form")
      end
    end
  end

  describe "PATCH #update" do
    let(:update_params) { {account: {name: "Updated Name"}} }

    context "when not logged in" do
      it "redirects to login page" do
        patch account_path(account), params: update_params
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }

      it "updates the account and redirects to show" do
        patch account_path(account), params: update_params
        expect(response).to redirect_to(account_path(account))
        expect(account.reload.name).to eq("Updated Name")
      end

      it "renders edit on validation failure" do
        patch account_path(account), params: {account: {name: ""}}
        expect(response).to have_http_status(:success)
        expect(response.body).to include("<form")
      end
    end
  end

  describe "GET #show" do
    context "when not logged in" do
      it "redirects to login page" do
        get account_path(account)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }

      let(:report_double) do
        double(
          account_name: account.name,
          account: account,
          latest_balance: OpenStruct.new(amount: BigDecimal("123.45")),
          net_transferred: BigDecimal(50),
          earnings: BigDecimal(25),
          irr: 0.1,
          monthly_irrs: "",
          balances_in_period: ""
        )
      end

      before do
        allow(AccountReport).to receive(:new)
          .with(user: user, account: account, currency: "default")
          .and_return(report_double)
        get account_path(account)
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:success)
      end

      it "renders the account header with account name" do
        expect(response.body).to include("<h1>#{account.name}</h1>")
      end
    end
  end

  describe "GET #reset" do
    let(:account_to_reset) { accounts(:savings_account) }

    context "when not logged in" do
      it "redirects to login page" do
        get account_reset_path(account_to_reset)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      stub_current_user { user }
      before { allow_any_instance_of(Account).to receive(:reset!).and_return(true) }

      it "redirects to account movements path" do
        get account_reset_path(account_to_reset)
        expect(response).to redirect_to(account_movements_path(account_to_reset))
      end

      context "when user has notifications enabled" do
        before do
          user.update!(settings: {"send_email_after_update" => true})
          allow(ServicesMailer).to receive(:new_daily_update).and_return(double(deliver_now: true))
        end

        it "sends a daily update email" do
          get account_reset_path(account_to_reset)
          expect(ServicesMailer).to have_received(:new_daily_update).with(user)
        end
      end

      context "when user has notifications disabled" do
        before do
          user.update!(settings: {"send_email_after_update" => false})
          allow(ServicesMailer).to receive(:new_daily_update)
        end

        it "does not send a daily update email" do
          get account_reset_path(account_to_reset)
          expect(ServicesMailer).not_to have_received(:new_daily_update)
        end
      end
    end
  end
end
