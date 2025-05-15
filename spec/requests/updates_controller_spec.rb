require "rails_helper"

RSpec.describe UpdatesController, type: :request do
  fixtures :users, :accounts
  let(:user) { users(:test_user) }

  describe "GET #show" do
    let(:updateable_account) do
      # create an account the user can update (non-default platform)
      user.accounts.create!(name: "Updatable", currency: "MXN", platform: :bitso)
    end

    context "when user is not logged in" do
      it "redirects to the login page" do
        get account_update_path(updateable_account, format: :json)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when user is logged in" do
      stub_current_user { user }

      context "and the account is not updateable" do
        let(:account) { accounts(:savings_account) }

        it "returns a JSON error payload" do
          get account_update_path(account, format: :json)
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("application/json")
          json = JSON.parse(response.body)
          expect(json["success"]).to eq(false)
          expect(json["message"]).to match(/no fue encontrada/)  # Spanish error message
        end
      end

      context "and the account is updateable" do
        before do
          # stub external balance fetch
          allow(Updaters::Bitso).to receive(:current_balance_for).with(updateable_account).and_return(BigDecimal("123.45"))
        end

        it "creates today’s balance, marks it validated, and redirects back" do
          expect {
            get account_update_path(updateable_account, format: :json)
          }.to change { Balance.where(account: updateable_account, date: Date.current).count }.by(1)
          balance = Balance.find_by(account: updateable_account, date: Date.current)
          expect(balance.amount_cents).to eq(12345)  # 123.45 * 100
          expect(balance.validated).to be true
          expect(response).to redirect_to(account_path(updateable_account))
        end

        context "when user has notifications enabled" do
          before do
            user.update!(settings: {"send_email_after_update" => true})
            allow(ServicesMailer).to receive(:new_daily_update)
              .and_return(double(deliver_now: true))
          end

          it "sends the daily update email" do
            get account_update_path(updateable_account, format: :json)
            expect(ServicesMailer).to have_received(:new_daily_update).with(user)
          end
        end

        context "when user has notifications disabled" do
          before do
            user.update!(settings: {"send_email_after_update" => false})
            allow(ServicesMailer).to receive(:new_daily_update)
          end

          it "does not send the daily update email" do
            get account_update_path(updateable_account, format: :json)
            expect(ServicesMailer).not_to have_received(:new_daily_update)
          end
        end
      end
    end
  end
end
