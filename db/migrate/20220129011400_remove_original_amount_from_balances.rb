class RemoveOriginalAmountFromBalances < ActiveRecord::Migration[7.0]
  def change
    remove_column :balances, :original_amount_cents, :integer
  end
end
