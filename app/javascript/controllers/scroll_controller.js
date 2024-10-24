import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.info('scroll_controller');
  }

  cancelWindowScrolling(evt) {
    evt.preventDefault();
    evt.stopPropagation();
  }
}
