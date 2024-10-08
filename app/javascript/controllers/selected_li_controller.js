import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['item'];

  // A tag click
  changeSelected(evt) {
    console.log("-- changeSelected()")
    this.updateListSelectionStatus(evt.currentTarget);
  }

  updateListSelectionStatus(aTag) {
    this.itemTargets.forEach(li => {
      delete li.dataset.selected;
      if (li.contains(aTag)) {
        li.dataset.selected = 'true';
      }
    });
  }

  // LI tag selected
  selectPrevItem(evt) {
    console.log("-- selectPrevItem()")
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

  // LI tag selected
  selectNextItem(evt) {
    console.log("-- selectNextItem")
    let next_item = null;
    const len = this.itemTargets.length;
    for (let i = 0; i < len; ++i) {
      console.log("-- selectNextItem: "+ i);
      if (this.itemTargets[i] == evt.currentTarget) {
        next_item = i + 1;
        if (next_item != null && next_item < len) {
          console.log("-- selectNextItem: next_item: "+ next_item);

          this.#enterItem(this.itemTargets[next_item]);
        }
        break;
      }
    }
  }

  // RIGHT key from selected LI tag on channel
  selectItem(evt) {
    console.log("-- selectItem()")
    const li = document.getElementById('items').querySelectorAll('li').item(0);
    if (li) {
      this.#enterItem(li);
    }
  }

  // SPACE key from selected LI tag on channel
  selectUnreadItem(evt) {
    console.log("-- selectUnreadItem()")
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

  // ENTER key from selected LI tag
  openUrl(evt) {
    console.log("-- openUrl()")
    window.open(evt.currentTarget.dataset.url, '_blank', 'noreferrer');
  }

  // private

  #enterItem(li) {
    console.log("-- #enterItem()")
    li.focus(); // Important for being the base point for next and previous
    const aTag = li.getElementsByTagName('A').item(0);
    aTag.click(); // This is going to invoke changeSelected()
  }
}
