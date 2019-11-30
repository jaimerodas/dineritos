desc "Updates all accounts when possible"
task get_latest_balances: :environment do
  UpdateAllAccounts.run
end
