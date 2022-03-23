class AddValidatedToBalances < ActiveRecord::Migration[7.0]
  def change
    add_column :balances, :validated, :boolean, default: false, nil: false
  end
end
