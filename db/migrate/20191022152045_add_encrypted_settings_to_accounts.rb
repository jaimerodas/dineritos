class AddEncryptedSettingsToAccounts < ActiveRecord::Migration[6.0]
  def up
    add_column :accounts, :settings_ciphertext, :text
    Lockbox.migrate(Account)
  end

  def down
    remove_column :accounts, :settings_ciphertext, :text
  end
end
