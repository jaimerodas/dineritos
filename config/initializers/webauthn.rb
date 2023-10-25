WebAuthn.configure do |config|
  # This value needs to match `window.location.origin` evaluated by
  # the User Agent during registration and authentication ceremonies.
  config.origin = (Rails.env == "development") ? "http://localhost:3000" : ENV["WEBAUTHN_HOST"]

  # Relying Party name for display purposes
  config.rp_name = "Dineritos"
end
