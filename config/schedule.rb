# Custom job type for running rake tasks inside the Kamal container
job_type :docker_rake,
  "docker exec dineritos-web bundle exec rake :task >> /var/log/dineritos-cron.log 2>&1"

# Update all account balances — daily at 5:00 AM CST (11:00 UTC)
every 1.day, at: "11:00 am" do
  docker_rake "get_latest_balances"
end

# Clean up expired sessions — 1st of each month at 3:00 AM CST (9:00 UTC)
every "0 9 1 * *" do
  docker_rake "remove_expired_sessions"
end
