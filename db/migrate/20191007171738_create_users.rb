class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :uid
      t.timestamps

      t.index :email, unique: true, where: "email IS NOT NULL"
      t.index :uid, unique: true, where: "uid IS NOT NULL"
    end
    # Affected tables
    tables = %i[accounts balance_dates sessions]

    # Adds a relationship between users and their data
    tables.each { |table| add_reference table, :user, foreign_key: true }

    reversible do |dir|
      # Only when running the migration (not the rollback!)
      dir.up do
        # Create the first user from configuration parameters
        user = User.create(email: Rails.application.credentials[:email])

        # Assign that user to all the old data
        [Account, BalanceDate, Session].each { |model| model.all.update_all(user_id: user.id) }
      end
    end

    # Prevent any new data from being created without a user
    tables.each { |table| change_column_null table, :user_id, false }
  end
end
