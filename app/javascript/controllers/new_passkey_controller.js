import { Controller } from '@hotwired/stimulus'
import * as Credential from 'plugins/credential'

export default class extends Controller {
  create (event) {
    event.preventDefault()

    const headers = new Headers()
    const action = event.target.action
    const options = {
      method: event.target.method,
      headers,
      body: new FormData(event.target)
    }

    fetch(action, options).then((response) => {
      if (response.ok) {
        const nickname = event.target.querySelector("input[name='passkey[nickname]']").value
        ok(response, nickname)
      } else {
        err(response)
      }
    })

    function ok (response, nickname) {
      response.json().then((data) => {
        const destination_url = '/opciones'
        const callback_url = `/passkeys/callback?nickname=${nickname}`
        Credential.create(encodeURI(destination_url), encodeURI(callback_url), data)
      })
    }
  }
}
