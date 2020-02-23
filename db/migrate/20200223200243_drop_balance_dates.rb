class DropBalanceDates < ActiveRecord::Migration[6.0]
  def change
    drop_table :balance_dates
  end
end
