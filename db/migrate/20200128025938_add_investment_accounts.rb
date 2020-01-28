class AddInvestmentAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :account_type, :integer, null: false, default: 0

    up_only do
      Account
        .where(platform: %w[yo_te_presto briq afluenta la_tasa cetes_directo red_girasol])
        .each { |account| account.update_attribute(:account_type, :investment) }
    end
  end
end
