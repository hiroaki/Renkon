import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.info("keyevent_controller")
  }

  cancelScrollByKeydown(evt) {
    switch(evt.keyCode) {
      case 38:
      case 40:
        evt.preventDefault();
        evt.stopPropagation();
        break;
    }
  }

  keyupEnter(evt) {
    // console.info("keyevent_controller#keyup_enter", evt)
    // console.info("keyevent_controller#keyup_enter", evt.target.dataset.url)
    switch(evt.keyCode) {
      case 37:
        console.info('left');
        break;
      case 38:
        console.info('up');
        if (this.focusPrevItem(evt.target)) {
          // console.log('stopImmediatePropagation: '+ evt.cancelable);
          // evt.preventDefault();
          // evt.stopPropagation();
          // evt.stopImmediatePropagation();
        }
        break;
      case 39:
        console.info('right');
        break;
      case 40:
        console.info('down');
        if (this.focusNextItem(evt.target)) {
          // console.log('stopImmediatePropagation: '+ evt.cancelable);
          // evt.preventDefault();
          // evt.stopPropagation();
          // evt.stopImmediatePropagation();
        }
        break;
      case 13:
        console.info('enter');
        break;
      case 8:
        console.info('delete');
        break;
      default:
        console.info(evt.keyCode);
    }
    console.info('shiftKey: '+ evt.shiftKey);
  }

  focusNextItem(elem) {
    let items = document.querySelectorAll("li[data-model='item']")
    let len = items.length;
    let next_item = null;
    for(var i =0; i < len; ++i ){
      if (items.item(i) == document.activeElement) {
        next_item = i + 1;
        break;
      }
    }
    if (next_item != null && next_item < len ) {
      items.item(next_item).focus();
      return true;
    }
    else {
      return false;
    }
  }

  focusPrevItem(elem) {
    let items = document.querySelectorAll("li[data-model='item']")
    let len = items.length;
    let prev_item = null;
    for(var i =0; i < len; ++i ){
      if (items.item(i) == document.activeElement) {
        prev_item = i - 1;
        break;
      }
    }
    if (prev_item != null && 0 <= prev_item) {
      items.item(prev_item).focus();
      return true;
    }
    else {
      return false;
    }
  }
}
