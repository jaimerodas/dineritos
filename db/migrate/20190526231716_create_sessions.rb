class CreateSessions < ActiveRecord::Migration[6.0]
  def change
    create_table :sessions do |t|
      t.string :token, null: false, index: {unique: true}
      t.datetime :valid_until, null: false
      t.datetime :claimed_at
    end
  end
end
