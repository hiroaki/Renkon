import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['listItem'];

  connect() {
    // INTERFACE - adapted by other controllers via this element
    console.log("this.identifier: "+ this.identifier); // 'subscriptions' or 'articles'
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

  // リストアイテムをクリックした時。そのアイテムを「選択状態」にします。
  handlerEnterItem(evt) {
    const li = this.detectLiFrom(evt.target);
    this.activateItem(li);
  }

  // イベントを発生させた要素を含むリストの、イベント要素のひとつ前の li を「選択状態」にします。
  // ここで想定しているのは、ある li がフォーカスされている状態から、カーソルキーの上を押下したとき。
  selectPrevItem(evt) {
    const li = this.detectLiFrom(evt.target);
    this.selectPrevLi(li);
  }

  selectPrevLi(li) {
    let prev_item = null;
    const len = this.listItemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.listItemTargets[i] == li) {
        prev_item = i - 1;
        if (prev_item != null && 0 <= prev_item) {
          this.activateItem(this.listItemTargets[prev_item]);
        }
        break;
      }
    }
  }

  // イベントを発生させた要素を含むリストの、イベント要素のひとつ次の li を「選択状態」にします。
  // ここで想定しているのは、ある li がフォーカスされている状態から、カーソルキーの下を押下したとき。
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
          this.activateItem(this.listItemTargets[next_item]);
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

  // 与えられた <li> を「選択状態」にし、 <li> が内包する要素からリンクを取得し、指定される <turbo-frame> に表示します。
  // <li> は次の条件を満たす <span> をひとつ含みます：
  // - data-link-to-url 属性にリンク先の URL
  // - data-link-to-frame 属性にリンク先の URL の内容を表示するための turbo-frame 名
  // この <span> は <a> の代替です。ブラウザの <a> の挙動をカスタムするために手動で行うための工夫です。
  activateItem(li) {
    this.moveFocusToItem(li); // Important for being the base point for next and previous

    const span = li.querySelector('span[data-link-to-url]');
    const url = span.dataset['linkToUrl'];
    const frame = document.querySelector(`turbo-frame[id=${span.dataset['linkToFrame']}]`);
    frame.src = url;

    this.fireChangeSelectedLiEvent(this.element, this.#updateListSelectionStatus(span));
  }

  #updateListSelectionStatus(currentTag) {
    let newSelectedLi = null;

    this.listItemTargets.forEach(li => {
      delete li.dataset.selected;
      if (li.contains(currentTag)) {
        li.dataset.selected = 'true';
        newSelectedLi = li;
      }
    });

    return newSelectedLi;
  }

  detectLiFrom(elem) {
    return elem.closest('li')
  }

  activateFirstItem() {
    const li = this.element.querySelector('li');
    if (li) {
      this.activateItem(li);
    }
  }

  getSelectedItem() {
    return this.element.querySelector('li[data-selected="true"]');
  }

  getSelectedItems() {
    return this.element.querySelectorAll('li[data-selected="true"]');
  }

  moveFocusToItem(li) {
    li.focus();
    return li;
  }

  setFocusToCurrentItem() {
    const li = this.getSelectedItem();
    if (li) {
      li.focus();
      return true;
    } else {
      return false;
    }
  }
}
