import { Controller } from "@hotwired/stimulus"
import { getCsrfToken, clearItemsPane, clearContentsPane } from 'lib/schema'

export default class extends Controller {
  //
  confirmEmptyTrash(evt) {
    const message = evt.currentTarget.dataset['textForConfirmEmptyTrash'] || 'Sure?';
    if (!confirm(message)) {
      evt.stopImmediatePropagation()
    }
  }

  //
  emptyTrash(evt) {
    const url = evt.currentTarget.dataset['urlEmptyTrash'];

    return fetch(url, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': getCsrfToken() }
    })
    .then(response => {
      if (response.ok) {
        console.log('response ok, nothing to do', response);
        this.fireEmptyTrash();
      }
      else {
        console.error('Failed to delete the item', response);
      }
    })
    .catch(error => console.error('Error:', error));
  }

  fireEmptyTrash() {
    console.log("create emptyTrash event")
    const event = new CustomEvent('emptyTrash', {
      detail: { message: 'Hello from custom event!' },
      bubbles: true,
    });
    this.element.dispatchEvent(event);
  }
}
