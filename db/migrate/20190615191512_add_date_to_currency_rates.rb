class AddDateToCurrencyRates < ActiveRecord::Migration[6.0]
  def up
    add_column :currency_rates, :date, :date

    CurrencyRate.all.each do |rate|
      rate.update_columns(date: BalanceDate.find(rate.balance_date_id).date)
    end

    change_column_null :currency_rates, :date, false
    add_index :currency_rates, [:date, :currency], unique: true

    remove_reference :currency_rates, :balance_date
  end

  def down
    add_reference :currency_rates, :balance_date

    CurrencyRate.all.each do |rate|
      rate.update_columns(balance_date_id: BalanceDate.find_by(date: rate.date).id)
    end

    change_column_null :currency_rates, :balance_date_id, false

    remove_index :currency_rates, [:date, :currency]
    remove_column :currency_rates, :date, :date
  end
end
