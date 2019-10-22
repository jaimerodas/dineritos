class RemoveUnencryptedSettingsFromAccounts < ActiveRecord::Migration[6.0]
  def change
    remove_column :accounts, :settings, :jsonb
  end
end
