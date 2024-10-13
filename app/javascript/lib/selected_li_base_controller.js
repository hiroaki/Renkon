import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['item'];

  connect() {
    this.element[this.identifier] = this;
    this.element['selectedLi'] = this;
  }

  // A tag click
  changeSelected(evt) {
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
    this.selectPrevLi(evt.currentTarget);
  }

  selectPrevLi(li) {
    let prev_item = null;
    const len = this.itemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.itemTargets[i] == li) {
        prev_item = i - 1;
        if (prev_item != null && 0 <= prev_item) {
          this.enterItem(this.itemTargets[prev_item]);
        }
        break;
      }
    }
  }

  // LI tag selected
  selectNextItem(evt) {
    this.selectNextLi(evt.currentTarget);
  }

  selectNextLi(li) {
    let next_item = null;
    const len = this.itemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.itemTargets[i] == li) {
        next_item = i + 1;
        if (next_item != null && next_item < len) {
          this.enterItem(this.itemTargets[next_item]);
        }
        break;
      }
    }
  }

  // ENTER key from selected LI tag
  openUrl(evt) {
    window.open(evt.currentTarget.dataset.url, '_blank', 'noreferrer');
  }

  enterItem(li) {
    li.focus(); // Important for being the base point for next and previous
    const aTag = li.getElementsByTagName('A').item(0);
    aTag.click(); // This is going to invoke changeSelected()
  }

  // li 以外をクリックしてフォーカスが移動すると、 li に選択状態にありながらも
  // キーイベントがそこでは発生しなくなってしまうため、
  // このメソッドにより "selected" の最後のものにフォーカスを移動させます。
  // NOTE: 複数選択状態は現在のところ未実装ですが、今後実装が予定されています。
  focusLastSelectedLi() {
    let lastSelected = null;

    this.itemTargets.forEach(li => {
      if (li.dataset.selected == 'true') {
        lastSelected = li;
      }
    });

    if (lastSelected) {
      lastSelected.focus({ preventScroll: true, focusVisible: false });
    }
  }
}
