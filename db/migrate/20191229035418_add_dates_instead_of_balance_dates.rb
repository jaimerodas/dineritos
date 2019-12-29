class AddDatesInsteadOfBalanceDates < ActiveRecord::Migration[6.0]
  def up
    {balances: Balance, totals: Total}.each do |table, model|
      # Agrega la columna
      add_column table, :date, :date

      # Agrega la info a la columna nueva
      model.all.each { |row| row.update_column(:date, row.balance_date.date) }

      # Una vez que ya hay info, podemos hacer la columna NULL: FALSE
      change_column_null table, :date, false

      # Y como solo puede haber un saldo al día, lo hacemos UNIQUE
      columns_affected = table.eql?(:totals) ? :date : [:date, :account_id]
      add_index table, columns_affected, unique: true

      # Finalmente, quitamos la columna anterior
      remove_reference table, :balance_date
    end
  end

  def down
    {balances: Balance, totals: Total}.each do |table, model|
      # Regresa la relación a balance_dates
      add_reference table, :balance_date

      # Regresa la información
      model.all.each do |row|
        balance_date_id = BalanceDate.find_by(date: row.date).id
        row.update_column(:balance_date_id, balance_date_id)
      end

      # Reestablece el que a huevo deba haber una relación declarada
      change_column_null table, :balance_date_id, false

      # Quita la columna nueva
      remove_column table, :date, :date
    end
  end
end
