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
      let(:fake_new_account) do
        instance_double(Account, name: "New Account", new_and_empty?: true).tap do |account|
          allow(account).to receive(:to_model).and_return(account)
          allow(account).to receive(:model_name).and_return(Account.model_name)
          allow(account).to receive(:to_param).and_return("999")
          allow(account).to receive(:persisted?).and_return(true)
        end
      end
      let(:fake_disabled_account) do
        double(name: "Disabled Account", active: false)
      end
      let(:fake_report) do
        double(
          accounts: [fake_account_row],
          totals: {balance: BigDecimal(100), earnings: BigDecimal(10), transfers: BigDecimal(20)},
          new_accounts: [fake_new_account],
          disabled_accounts: [fake_disabled_account]
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

      it "calls the report with correct parameters and methods" do
        expect(AccountsComparisonReport).to receive(:new)
          .with(user: user, period: AccountsController::DEFAULT_PERIOD)
          .and_return(fake_report)
        expect(fake_report).to receive(:accounts).and_return([fake_account_row])
        expect(fake_report).to receive(:totals).and_return({balance: BigDecimal(100), earnings: BigDecimal(10), transfers: BigDecimal(20)})
        expect(fake_report).to receive(:new_accounts).and_return([fake_new_account])
        expect(fake_report).to receive(:disabled_accounts).and_return([fake_disabled_account])
        get accounts_path
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
          new_account_id = user.accounts.last.id
          expect(response).to redirect_to(account_path(new_account_id))
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
          balances_in_period: "",
          earliest_year: 2023,
          period_text: "past_year",
          starting_balance: BigDecimal(100),
          deposits: BigDecimal(50),
          withdrawals: BigDecimal(0),
          final_balance: BigDecimal(160),
          monthly_pnl: [
            {
              month: "2023-12",
              initial_balance: BigDecimal(100),
              deposits: BigDecimal(50),
              withdrawals: BigDecimal(0),
              earnings: BigDecimal(10),
              final_balance: BigDecimal(160)
            }
          ],
          total_pnl: {
            deposits: BigDecimal(50),
            withdrawals: BigDecimal(0),
            earnings: BigDecimal(10)
          }
        )
      end

      before do
        allow(AccountReport).to receive(:new)
          .with(user: user, account: account, currency: "default", period: "past_year")
          .and_return(report_double)
      end

      context "when account is new and empty" do
        let(:empty_report_double) do
          double(
            account_name: account.name,
            account: account,
            earliest_year: Date.current.year,
            period_text: "past_year",
            starting_balance: BigDecimal(0),
            deposits: BigDecimal(0),
            withdrawals: BigDecimal(0),
            earnings: BigDecimal(0),
            final_balance: BigDecimal(0),
            monthly_pnl: [],
            total_pnl: {}
          )
        end

        before do
          allow(account).to receive(:new_and_empty?).and_return(true)
          allow(AccountReport).to receive(:new)
            .with(user: user, account: account, currency: "default", period: "past_year")
            .and_return(empty_report_double)
          get account_path(account)
        end

        it "returns a successful response" do
          expect(response).to have_http_status(:success)
        end

        it "renders the account header with account name" do
          expect(response.body).to include("<h1>#{account.name}</h1>")
        end

        it "shows the account header" do
          expect(response.body).to include("Resumen")
        end

        it "shows empty state with call to action" do
          expect(response.body).to include("Aquí veras un detalle mensual de esta cuenta una vez que")
          expect(response.body).to include("agregues un saldo inicial")
          expect(response.body).not_to include("Saldo Inicial")
          expect(response.body).not_to include("2023-12")
        end
      end

      context "when account has balances" do
        before do
          allow(account).to receive(:new_and_empty?).and_return(false)
          get account_path(account)
        end

        it "returns a successful response" do
          expect(response).to have_http_status(:success)
        end

        it "renders the account header with account name" do
          expect(response.body).to include("<h1>#{account.name}</h1>")
        end

        it "renders the profit and loss table with data" do
          expect(response.body).to include("2023-12")
          expect(response.body).to include("Saldo Inicial")
          expect(response.body).to include("Depósitos")
        end

        it "does not show the banner for new empty accounts" do
          expect(response.body).not_to include("¡Agrega tu primer saldo para ver información!")
        end
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
