desc "Updates all accounts when possible"
task :get_latest_balances => :environment do
  Account.updateable.each do |account|
    puts "Actualizando #{account.name}"
    balance = account.latest_balance
    puts "Obtuve #{balance}"
    puts "----------------"
  end
end
