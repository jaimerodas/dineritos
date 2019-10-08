class RemakeSessionsTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :sessions
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false, index: {unique: true}
      t.string :remember_digest
      t.datetime :expires_at, null: false
      t.index :remember_digest, unique: true, where: "remember_digest IS NOT NULL"
    end
  end

  def down
    drop_table :sessions
    create_table :sessions do |t|
      t.string :token, null: false, index: {unique: true}
      t.datetime :valid_until, null: false
      t.datetime :claimed_at
      t.references :user, foreign_key: true
    end
  end
end
