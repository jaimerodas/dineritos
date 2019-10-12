class CreateBalance
  def self.from(user:, params:)
    new(user: user, params: params).run
  end

  def initialize(user:, params:)
    @user = user
    @params = params
  end

  attr_accessor :user, :params

  def run
    @balance_date = user.balance_dates.find_or_create_by(date: Date.today)
    remove_data_from_same_date
    create_balances_from_form
    create_balances_on_bitso_accounts

    CalculateTotal.from(@balance_date)
    DeactivateAccounts.from(@balance_date)
  end

  private

  def remove_data_from_same_date
    @balance_date.balances.destroy_all
    @balance_date.total&.destroy
  end

  def create_balances_from_form
    params.each do |key, balance_params|
      @balance_date.balances.create(balance_params)
    end
  end

  def create_balances_on_bitso_accounts
    user.accounts.bitso.each do |account|
      amount = BitsoService.current_balance_for(account)
      next if amount.zero? && !account.active?

      @balance_date.balances.create(
        account_id: account.id,
        amount: amount
      )

      account.update_attribute(:active, true) if !amount.zero? && !account.active?
    end
  end
end
