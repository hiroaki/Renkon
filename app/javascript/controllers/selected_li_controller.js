import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['item'];

  connect() {
    console.info('selected_li_controller');
  }

  select(evt) {
    console.info('selected_li_controller#select');

    this.itemTargets.forEach(item => {
      item.classList.remove('text-white', '!bg-neutral-600');
    });

    event.currentTarget.classList.add('text-white', '!bg-neutral-600');
  }

  selectPrevItem(evt) {
    let prev_item = null;
    const len = this.itemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.itemTargets[i] == evt.currentTarget) {
        prev_item = i - 1;
        break;
      }
    }
    if (prev_item != null && 0 <= prev_item) {
      const elem = this.itemTargets[prev_item]
      elem.focus();
      elem.getElementsByTagName('A').item(0).click();
      return elem;
    }
    else {
      return null;
    }
  }

  selectNextItem(evt) {
    let next_item = null;
    const len = this.itemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.itemTargets[i] == evt.currentTarget) {
        next_item = i + 1;
        break;
      }
    }
    if (next_item != null && next_item < len) {
      const elem = this.itemTargets[next_item]
      elem.focus();
      elem.getElementsByTagName('A').item(0).click();
      return elem;
    }
    else {
      return null;
    }
  }

  openUrl(evt) {
    window.open(evt.currentTarget.dataset.url, '_blank', 'noreferrer');
  }
}
