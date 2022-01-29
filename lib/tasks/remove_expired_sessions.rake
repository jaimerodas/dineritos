desc "Removes expired sessions from db"
task remove_expired_sessions: :environment do
  Session.expired.destroy_all
end
