import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.info('scroll_controller');
  }

  cancelWindowScrolling(evt) {
    switch(evt.keyCode) {
      case 38:
      case 40:
        // cancel window scrolling
        evt.preventDefault();
        evt.stopPropagation();
        break;
    }
  }
}
