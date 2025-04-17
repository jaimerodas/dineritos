class PasskeysController < ApplicationController
  before_action :auth

  def new
    @passkey = current_user.passkeys.new
  end

  def create
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        name: current_user.email,
        id: current_user.uid
      },
      authenticator_selection: {user_verification: "required"}
    )

    current_user.save
    session[:create_challenge] = create_options.challenge

    respond_to do |format|
      format.json { render json: create_options }
    end
  end

  def callback
    pp params
    webauthn_credential = WebAuthn::Credential.from_create(params)
    webauthn_credential.verify(session[:create_challenge])

    credential = current_user.passkeys.build(
      external_id: Base64.strict_encode64(webauthn_credential.raw_id),
      nickname: params[:nickname],
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count
    )

    if credential.save
      render json: {status: "ok"}, status: :ok
    else
      render json: "Couldn't register your Security Key", status: :unprocessable_entity
    end
  rescue WebAuthn::Error => e
    render json: "Verification failed: #{e.message}", status: :unprocessable_entity
  ensure
    session.delete("create_challenge")
  end

  # DELETE /passkeys/:id
  def destroy
    passkey = current_user.passkeys.find(params[:id])
    passkey.destroy
    redirect_to settings_path, notice: "Passkey eliminada"
  end
end
