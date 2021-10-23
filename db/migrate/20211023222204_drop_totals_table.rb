class DropTotalsTable < ActiveRecord::Migration[6.1]
  def change
    drop_table :totals do |t|
      t.integer :amount_cents, null: false
      t.date :date
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
