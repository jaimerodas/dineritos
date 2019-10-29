class AddCacheToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :last_balance_cents, :integer
    add_column :accounts, :last_balance_updated_at, :datetime
  end
end
