class CreateBalanceDates < ActiveRecord::Migration[6.0]
  def change
    create_table :balance_dates do |t|
      t.date :date, null: false, index: {unique: true}
    end
  end
end
