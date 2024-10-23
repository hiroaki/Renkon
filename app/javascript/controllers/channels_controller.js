import SelectedLiBaseController from "lib/selected_li_base_controller"

export default class extends SelectedLiBaseController {
  confirmDestroy(evt) {
    const message = evt.currentTarget.dataset['textForConfirmDestroy'] || 'Sure?';
    if (!confirm(message)) {
      evt.stopImmediatePropagation()
    }
  }

  destroyChannel(evt) {
    const me = this;
    const li = evt.currentTarget;
    const url = li.dataset['urlDestroy'];

    return fetch(url, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]').content
      }
    })
    .then(response => {
      if (response.ok) {
        li.remove();
      }
      else {
        console.error('Failed to delete the channel', response);
      }
    })
    .catch(error => console.error('Error:', error));
  }
}
