class AddAccountTypeToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :account_type, :integer
    add_column :accounts, :settings, :jsonb

    reversible do |dir|
      dir.up do
        Account.all.update_all(account_type: 0)
      end
    end

    change_column :accounts, :account_type, :integer, null: false, default: 0
  end
end
