import * as WebAuthnJSON from '@github/webauthn-json'

function getCSRFToken () {
  const CSRFSelector = document.querySelector('meta[name="csrf-token"]')
  if (CSRFSelector) {
    return CSRFSelector.getAttribute('content')
  } else {
    return null
  }
}

function callback (destinationUrl, url, body) {
  fetch(url, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': getCSRFToken()
    },
    credentials: 'same-origin'
  }).then(function (response) {
    if (response.ok) {
      window.location.replace(destinationUrl)
    } else if (response.status < 500) {
      // Handle client error - could show user-friendly message
      response.text().then(text => {
        // In development, you might want to log: console.error('Client error:', text)
        // For production, show user-friendly error
      })
    } else {
      // Handle server error - show user-friendly message
      // In development: console.error('Server error')
    }
  })
}

function create (destinationUrl, callbackUrl, credentialOptions) {
  WebAuthnJSON.create({ publicKey: credentialOptions }).then(function (credential) {
    callback(destinationUrl, callbackUrl, credential)
  }).catch(function (error) {
    // Handle WebAuthn creation error
    // In development: console.error('WebAuthn creation failed:', error)
    // Show user-friendly error message
  })

  // Creating new public key credential...
}

function get (data) {
  WebAuthnJSON.get({ publicKey: data.get_options }).then(function (credentials) {
    callback('/', data.callback_url, credentials)
  }).catch(function (error) {
    // Handle WebAuthn get error
    // In development: console.error('WebAuthn authentication failed:', error)
    // Show user-friendly error message
  })

  // Getting public key credential...
}

export { create, get }
