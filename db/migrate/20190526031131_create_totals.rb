class CreateTotals < ActiveRecord::Migration[6.0]
  def change
    create_table :totals do |t|
      t.references :balance_date, null: false, foreign_key: true
      t.integer :amount_cents, null: false

      t.timestamps
    end
  end
end
