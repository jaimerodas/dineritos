class DeactivateAccounts
  def self.from(balance_date)
    balance_date.balances.where(amount_cents: 0).each do |balance|
      balance.account.update_attribute(:active, false)
    end
  end
end
