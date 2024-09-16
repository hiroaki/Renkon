import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.info('keyevent_controller');
  }

  handlerKeydown(evt) {
    switch(evt.keyCode) {
      case 38:
      case 40:
        // cancel window scrolling
        evt.preventDefault();
        evt.stopPropagation();
        break;
    }
  }

  handlerKeyup(evt) {
    switch(evt.keyCode) {
      case 37:
        console.info('left');
        break;
      case 38:
        console.info('up');
        this.focusPrevItem(evt.target);
        break;
      case 39:
        console.info('right');
        this.clickLinkForItems(evt.target);
        break;
      case 40:
        console.info('down');
        this.focusNextItem(evt.target);
        break;
      case 13:
        console.info('enter');
        this.openWindow(evt.target.dataset.url);
        break;
      case 8:
        console.info('delete');
        break;
      default:
        console.info(evt.keyCode);
    }
    console.info('shiftKey: '+ evt.shiftKey);
  }

  clickLinkForItems(elem) {
    let a_tag = elem.querySelector('a[data-listen-keyevent="right"]');
    if (a_tag) {
      a_tag.click();
    }
  }

  openWindow(url) {
    return window.open(url, '_blank', 'noreferrer');
  }

  focusNextItem(elem) {
    const items = document.querySelectorAll('li[data-model="item"]')
    const len = items.length;
    let next_item = null;

    for (let i = 0; i < len; ++i) {
      if (items.item(i) == document.activeElement) {
        next_item = i + 1;
        break;
      }
    }
    if (next_item != null && next_item < len) {
      elem = items.item(next_item)
      elem.focus();
      return elem;
    }
    else {
      return null;
    }
  }

  focusPrevItem(elem) {
    const items = document.querySelectorAll('li[data-model="item"]')
    const len = items.length;
    let prev_item = null;

    for (let i = 0; i < len; ++i) {
      if (items.item(i) == document.activeElement) {
        prev_item = i - 1;
        break;
      }
    }
    if (prev_item != null && 0 <= prev_item) {
      elem = items.item(prev_item)
      elem.focus();
      return elem;
    }
    else {
      return null;
    }
  }
}
