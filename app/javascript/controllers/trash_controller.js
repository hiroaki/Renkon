import { Controller } from "@hotwired/stimulus"
import { getCsrfToken } from 'lib/schema'
import { fireEmptyTrashEvent } from 'lib/pane_focus_events'

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
    fireEmptyTrashEvent(this.element)
  }
}
