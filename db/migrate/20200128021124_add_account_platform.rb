class AddAccountPlatform < ActiveRecord::Migration[6.0]
  def change
    rename_column :accounts, :account_type, :platform
    remove_column :accounts, :last_balance_cents
    remove_column :accounts, :last_balance_updated_at
  end
end
