class CreateBalances < ActiveRecord::Migration[6.0]
  def change
    create_table :balances do |t|
      t.references :account, null: false, foreign_key: true
      t.references :balance_date, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.integer :original_amount_cents

      t.timestamps
    end
  end
end
