class CreateCurrencyRates < ActiveRecord::Migration[6.0]
  def change
    create_table :currency_rates do |t|
      t.references :balance_date, null: false, foreign_key: true
      t.string :currency, null: false
      t.bigint :rate_subcents, null: false

      t.timestamps
    end
  end
end
