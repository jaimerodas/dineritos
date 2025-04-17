class LoginsController < ApplicationController
  before_action :reverse_auth
  layout "login"

  def show
  end

  def create
    # Uniformly redirect to magic‑link step; do not reveal whether email exists
    redirect_to email_login_path(session: {email: params_email})
  end

  def email
    if valid_email?
      session = @user.sessions.create
      SessionsMailer.login(user: @user, token: session.token).deliver_now
    end
  end

  # GET /ingresar/discovery.json
  # WebAuthn discovery: prompt any resident credential, no email required
  def discovery
    options = WebAuthn::Credential.options_for_get(
      user_verification: "required"
    )
    session[:webauthn_discovery_challenge] = options.challenge
    render json: {
      callback_url: callback_login_path(format: :json),
      get_options: options
    }
  end

  def callback
    # Discovery mode: no email, find user by resident credential
    if session[:webauthn_discovery_challenge]
      webauthn_credential = WebAuthn::Credential.from_get(params)
      external = Base64.strict_encode64(webauthn_credential.raw_id)
      passkey = Passkey.find_by(external_id: external)
      unless passkey
        return render json: "Unknown credential", status: :unprocessable_entity
      end
      webauthn_credential.verify(
        session.delete(:webauthn_discovery_challenge),
        public_key: passkey.public_key,
        sign_count: passkey.sign_count,
        user_verification: true
      )
      passkey.update!(sign_count: webauthn_credential.sign_count)
      log_in(passkey.user)
      render json: {status: "ok"}, status: :ok
    end
  rescue WebAuthn::Error => e
    render json: "Verification failed: #{e.message}", status: :unprocessable_entity
  end

  private

  def valid_email?
    @user = User.find_by(email: params_email)
  end

  def params_email
    params.require(:session).permit(:email)[:email]&.downcase
  end

  def reverse_auth
    redirect_to root_path if logged_in?
  end
end
