// Ref: https://techracho.bpsinc.jp/hachi8833/2024_09_12/143416

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.focus();
  }

  hide(event) {
    event.preventDefault();

    this.element.remove();
  }

  hideOnSubmit(event) {
    if (event.detail.success) {
      this.hide();
    }
  }

  disconnect() {
    this.#modalTurboFrame.src = null;
  }

  // private

  get #modalTurboFrame() {
    return document.querySelector("turbo-frame[id='modal']");
  }
}
