class CreatePasskeys < ActiveRecord::Migration[7.0]
  def change
    create_table :passkeys do |t|
      t.string :nickname
      t.string :external_id
      t.string :public_key
      t.references :user, null: false, foreign_key: true
      t.bigint :sign_count, null: false, default: 0

      t.timestamps
      t.index :external_id, unique: true
    end
  end
end
