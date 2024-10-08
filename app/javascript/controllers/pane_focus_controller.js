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
}
