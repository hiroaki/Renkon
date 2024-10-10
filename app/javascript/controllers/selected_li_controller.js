import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['item'];

  toggleHighlight(evt) {
    this.itemTargets.forEach(item => {
      item.classList.remove('text-white', '!bg-neutral-600');
      if (item.contains(evt.currentTarget)) {
        item.classList.add('text-white', '!bg-neutral-600');
      }
    });
  }

  selectPrevItem(evt) {
    let prev_item = null;
    const len = this.itemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.itemTargets[i] == evt.currentTarget) {
        prev_item = i - 1;
        if (prev_item != null && 0 <= prev_item) {
          this.#enterItem(this.itemTargets[prev_item]);
        }
        break;
      }
    }
  }

  selectNextItem(evt) {
    let next_item = null;
    const len = this.itemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.itemTargets[i] == evt.currentTarget) {
        next_item = i + 1;
        if (next_item != null && next_item < len) {
          this.#enterItem(this.itemTargets[next_item]);
        }
        break;
      }
    }
  }

  selectItem(evt) {
    const li = document.getElementById('items').querySelectorAll('li').item(0);
    if (li) {
      this.#enterItem(li);
    }
  }

  selectUnreadItem(evt) {
    const items = document.getElementById('items').querySelectorAll('li');
    let pos = -1;
    for (let i = 0; i < items.length; ++i) {
      if (items[i] == evt.currentTarget) {
        pos = i;
        break;
      }
    }

    for (let i = pos + 1; i < items.length; ++i) {
      if (items[i].dataset['unread'] == 'true') {
        this.#enterItem(items[i]);
        break;
      }
    }
  }

  openUrl(evt) {
    window.open(evt.currentTarget.dataset.url, '_blank', 'noreferrer');
  }

  // private

  #enterItem(li) {
    li.focus();
    li.getElementsByTagName('A').item(0).click();
  }
}
