import { Controller } from "@hotwired/stimulus"
import * as Credential from "plugins/credential";

export default class extends Controller {
  create(event) {
    event.preventDefault();

    const headers = new Headers();
    const action = event.target.action;
    const options = {
      method: event.target.method,
      headers: headers,
      body: new FormData(event.target)
    };

    fetch(action, options).then((response) => {
      if (response.ok) {
        response.json().then((data) => {
          Credential.get(data);
        });
      } else {
        err(response);
      }
    });
  }
}
