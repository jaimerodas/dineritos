class CreateAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :currency, null: false, default: "MXN"
      t.boolean :active, null: false, default: 1

      t.timestamps
    end
  end
end
