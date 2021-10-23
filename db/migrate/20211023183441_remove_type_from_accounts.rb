class RemoveTypeFromAccounts < ActiveRecord::Migration[6.1]
  def change
    # WARNING: this will delete all records associated with checking accounts
    Account.where(account_type: 0).each do |account|
      account.balances.destroy_all
      account.destroy
    end

    remove_column :accounts, :account_type, :integer, default: 0, null: false
  end
end
