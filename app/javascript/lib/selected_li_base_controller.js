import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['listItem'];

  connect() {
    this.element[this.identifier] = this;
    this.element['selectedLi'] = this;
  }

  fireChangeSelectedLiEvent(elem, newSelectedLi) {
    const event = new CustomEvent('changeSelectedLi', {
      detail: { selected: newSelectedLi },
      bubbles: true,
    });

    elem.dispatchEvent(event);
  }

  changeSelected(evt) {
    this.fireChangeSelectedLiEvent(this.element, this.#updateListSelectionStatus(evt.currentTarget));
  }

  #updateListSelectionStatus(aTag) {
    let newSelectedLi = null;

    this.listItemTargets.forEach(li => {
      delete li.dataset.selected;
      if (li.contains(aTag)) {
        li.dataset.selected = 'true';
        newSelectedLi = li;
      }
    });

    return newSelectedLi;
  }

  selectPrevItem(evt) {
    this.selectPrevLi(evt.currentTarget);
  }

  selectPrevLi(li) {
    let prev_item = null;
    const len = this.listItemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.listItemTargets[i] == li) {
        prev_item = i - 1;
        if (prev_item != null && 0 <= prev_item) {
          this.enterItem(this.listItemTargets[prev_item]);
        }
        break;
      }
    }
  }

  selectNextItem(evt) {
    const li = this.detectLiFrom(evt.target)
    this.selectNextLi(li);
  }

  selectNextLi(li) {
    let next_item = null;
    const len = this.listItemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.listItemTargets[i] == li) {
        next_item = i + 1;
        if (next_item != null && next_item < len) {
          this.enterItem(this.listItemTargets[next_item]);
        }
        break;
      }
    }
  }

  openUrl(evt) {
    const li = this.detectLiFrom(evt.target)
    if (li) {
      window.open(li.dataset.urlSource, '_blank', 'noopener noreferrer')
    } else {
      // このブロックへ来るのは、たとえばイベントをリッスンしている <ul> の中で発生したイベントであるも、
      // <li> の上ではない部分（いわゆる余白部分）で発生したとき。
      // ただし <ul> に class="h-full" などで高さを確保しておかないと、
      // <ul> はすべての <li> のサイズに（コンパクトに）なるので余白部分がない状態になり、
      // 見た目の余白部分でキーイベントのイベントが発生しなくなります。
      // 見た目の選択状態との兼ね合いに注意してください。
      // 現状は、余白をクリックしたあと、ある <li> が選択状態であれば、
      // キー Enter イベントは #open を実行し、またダブルクリックは実行せずにこのブロックへ来るようにしています。
      console.warn('<li> was undetected from the event target')
    }
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

    this.listItemTargets.forEach(li => {
      if (li.dataset.selected == 'true') {
        lastSelected = li;
      }
    });

    if (lastSelected) {
      lastSelected.focus({ preventScroll: true, focusVisible: false });
    }
  }

  detectLiFrom(elem) {
    return elem.closest('li')
  }
}
