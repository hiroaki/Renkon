import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['pane'];

  connect() {
    this.paneTargets.forEach((pane) => {
      pane.addEventListener('click', () => this.focusPane(pane));
    });
  }

  focusPane(pane) {
    this.paneTargets.forEach((pane) => pane.classList.remove('focused'));
    pane.classList.add('focused');
  }

  // keyup LEFT on items pane
  backToChannelPane(evt) {
    this.focusPane(this.paneTargets[0]);

    const selectedChannel = document.getElementById('channels').querySelector('li[data-selected="true"]');
    selectedChannel.focus();
  }

  // keyup RIGHT on channels pane
  forwardToItemPane(evt) {
    this.focusPane(this.paneTargets[1]);

    const selectedItems = document.getElementById('items').querySelectorAll('li[data-selected="true"]');
    if (0 < selectedItems.length) {
      selectedItems.item(selectedItems.length - 1).focus();
    }
    else {
      const li = document.getElementById('items').querySelectorAll('li').item(0);
      if (li) {
        li.closest('ul').items.enterItem(li);
      }
    }
  }

  // keyup SPACE on channels pane
  forwardToUnreadItemPane(evt) {
    this.focusPane(this.paneTargets[1]);

    const items = document.getElementById('items').querySelectorAll('li');
    let pos = -1;
    for (let i = 0; i < items.length; ++i) {
      if (items[i] == evt.currentTarget) {
        pos = i;
        break;
      }
    }

    for (let i = pos + 1; i < items.length; ++i) {
      let li = items[i];
      if (li.dataset['unread'] == 'true') {
        // call a method of items controller (based selected-li controller)
        li.closest('ul').items.enterItem(li);
        break;
      }
    }
  }
}
