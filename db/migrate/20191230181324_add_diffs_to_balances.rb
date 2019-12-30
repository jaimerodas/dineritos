class AddDiffsToBalances < ActiveRecord::Migration[6.0]
  def change
    add_column :balances, :transfers_cents, :integer, null: false, default: 0
    add_column :balances, :diff_cents, :integer
    add_column :balances, :diff_days, :integer
  end
end
