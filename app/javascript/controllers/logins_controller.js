import { Controller } from '@hotwired/stimulus'
import * as Credential from 'plugins/credential'

export default class extends Controller {
  static values = {
    discoveryUrl: String
  }

  // Automatically trigger passkey discovery on load, if supported
  connect () {
    if (window.PublicKeyCredential) {
      this.discover(new Event('autodiscover'))
    }
  }

  // Trigger WebAuthn discovery flow (resident credentials)
  discover (event = null) {
    // suppress default if this was a user event
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault()
    }
    fetch(this.discoveryUrlValue, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      credentials: 'same-origin'
    })
      .then(response => response.json())
      .then(data => {
        Credential.get(data)
      })
      .catch(err => console.error('Discovery error', err))
  }
}
