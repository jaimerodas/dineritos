class AddCurrencyToBalances < ActiveRecord::Migration[6.0]
  def change
    add_column :balances, :currency, :text, null: false, default: "MXN"
    remove_index :balances, [:date, :account_id]
    add_index :balances, [:date, :account_id, :currency], unique: true, name: "one_currency_balance_per_day"
  end
end
