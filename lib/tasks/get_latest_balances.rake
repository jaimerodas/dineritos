desc "Updates all accounts when possible"
task :get_latest_balances do
  Account.updateable.each(&:latest_balance)
end
