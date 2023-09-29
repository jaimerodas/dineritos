class LoginsController < ApplicationController
  before_action :reverse_auth
  layout "login"

  def show
  end

  def create
    if valid_email? && @user.passkeys.any?
      redirect_to choose_login_path(session: {email: params_email})
    else
      redirect_to email_login_path(session: {email: params_email})
    end
  end

  def email
    if valid_email?
      session = @user.sessions.create
      SessionsMailer.login(user: @user, token: session.token).deliver_now
    end
  end

  def choose
    @email = params_email
  end

  def passkey
    if valid_email?
      options = WebAuthn::Credential.options_for_get(
        allow: @user.passkeys.pluck(:external_id),
        user_verification: 'required'
      )

      session['current_authentication'] = {
        'challenge' => options.challenge,
        'username' => params_email
      }

      respond_to do |format|
        format.json { render json: {
          callback_url: callback_login_path(format: :json),
          get_options: options
        } }
      end
    end
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_get(params)
    user = User.find_by(email: session['current_authentication']['username'])
    passkey = user.passkeys.find_by(external_id: Base64.strict_encode64(webauthn_credential.raw_id))

    webauthn_credential.verify(
      session['current_authentication']['challenge'],
      public_key: passkey.public_key,
      sign_count: passkey.sign_count,
      user_verification: true
    )

    passkey.update!(sign_count: webauthn_credential.sign_count)
    log_in(user)
    render json: { status: 'ok' }, status: :ok
  rescue WebAuthn::Error => e
    render json: "Verification failed: #{e.message}", status: :unprocessable_entity
  ensure
    session.delete(:current_authentication)
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
