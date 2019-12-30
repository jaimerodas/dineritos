class AddUserToTotals < ActiveRecord::Migration[6.0]
  def change
    add_reference :totals, :user, foreign_key: true
    Total.update_all(user_id: User.first.id)
  end
end
