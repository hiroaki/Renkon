import { Controller } from "@hotwired/stimulus"
import { fireConnectedSelectedLiBaseController, fireChangeSelectedLiEvent } from 'lib/pane_focus_events'

export default class extends Controller {
  static targets = ['listItem'];
  static values = {
    multiSelect: { type: Boolean, default: false },
  }

  connect() {
    // INTERFACE - adapted by other controllers via this element
    this.element[this.identifier] = this; // 'subscriptions' or 'articles' which are subclasses
    fireConnectedSelectedLiBaseController(this);
    console.log(this.listItemTargets.length);
  }

  // リストアイテムをクリックした時。そのアイテムを「選択状態」にします。
  handlerEnterItem(evt) {
    const withShiftKey = evt.shiftKey; // boolean
    const withMetaKey = evt.metaKey; // "command" key on macOS, boolean

    const li = this.detectLiFrom(evt.target);
    if (!li) {
      return;
    }

    if (!this.multiSelectValue) {
      this.activateItem(li);
      this.anchorItem = li;
      return;
    }

    if (withShiftKey) {
      this.selectItemRange(li);
      this.moveFocusToItem(li);
      this.fireSelectionChanged(li);
      return;
    }

    if (withMetaKey) {
      this.toggleItemSelection(li);
      this.moveFocusToItem(li);
      this.anchorItem = li;
      this.fireSelectionChanged(li);
      return;
    }

    this.activateItem(li);
    this.anchorItem = li;
  }

  // イベントを発生させた要素を含むリストの、イベント要素のひとつ前の li を「選択状態」にします。
  // ここで想定しているのは、ある li がフォーカスされている状態から、カーソルキーの上を押下したとき。
  selectPrevItem(evt) {
    const li = this.detectLiFrom(evt.target);
    const newLi = this.selectAdjacentLi(li, -1);
    if (newLi) {
      this.activateItem(newLi);
    }
  }

  // イベントを発生させた要素を含むリストの、イベント要素のひとつ次の li を「選択状態」にします。
  // ここで想定しているのは、ある li がフォーカスされている状態から、カーソルキーの下を押下したとき。
  selectNextItem(evt) {
    const li = this.detectLiFrom(evt.target);
    const newLi = this.selectAdjacentLi(li, 1);
    if (newLi) {
      this.activateItem(newLi);
    }
  }

  selectAdjacentLi(li, direction) {
    const len = this.listItemTargets.length;
    for (let i = 0; i < len; ++i) {
      if (this.listItemTargets[i] === li) {
        const adjacentIndex = i + direction;
        if (adjacentIndex >= 0 && adjacentIndex < len) {
          return this.listItemTargets[adjacentIndex];
        }
        break;
      }
    }
  }

  openUrl(evt) {
    const li = this.detectLiFrom(evt.target);
    if (li) {
      window.open(li.dataset.urlSource, '_blank', 'noopener noreferrer');
    } else {
      // このブロックへ来るのは、たとえばイベントをリッスンしている <ul> の中で発生したイベントであるも、
      // <li> の上ではない部分（いわゆる余白部分）で発生したとき。
      // ただし <ul> に class="h-full" などで高さを確保しておかないと、
      // <ul> はすべての <li> のサイズに（コンパクトに）なるので余白部分がない状態になり、
      // 見た目の余白部分でキーイベントのイベントが発生しなくなります。
      // 見た目の選択状態との兼ね合いに注意してください。
      // 現状は、余白をクリックしたあと、ある <li> が選択状態であれば、
      // キー Enter イベントは #open を実行し、またダブルクリックは実行せずにこのブロックへ来るようにしています。
      console.warn('<li> was undetected from the event target');
    }
  }

  // 与えられた <li> を「選択状態」にし、 <li> が内包する要素からリンクを取得し、指定される <turbo-frame> に表示します。
  // ただし指定される <turbo-frame> が存在しない場合は Turbo.visit によるリンクの遷移を行います。
  // また、いずれの場合もリンク遷移ののち、イベント changeSelectedLi を着火します。
  // <li> は次の条件を満たす <span> をひとつ含みます：
  // - data-link-to-url 属性にリンク先の URL
  // - data-link-to-frame 属性にリンク先の URL の内容を表示するための turbo-frame 名
  // ちなみにこの <span> は <a> の代替です。ブラウザの <a> の挙動をカスタムするために手動で行うための工夫として <span> を用いています。
  activateItem(li) {
    this.moveFocusToItem(li); // Important for being the base point for next and previous

    const newSelectedLi = this.selectSingleItem(li);

    if (!this.multiSelectValue) {
      const span = li.querySelector('span[data-link-to-url]');
      if (span) {
        const url = span.dataset['linkToUrl'];
        const frame = document.querySelector(`turbo-frame[id=${span.dataset['linkToFrame']}]`);
        if (frame) {
          frame.src = url;
        } else {
          Turbo.visit(url);
        }
      }
    }

    this.fireSelectionChanged(newSelectedLi);
  }

  #updateListSelectionStatusExclusively(currentTag) {
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

  #updateListSelectionStatusConsecutive(currentTag) {

  }

  #updateListSelectionStatusAppend(currentTag) {

  }

  selectSingleItem(li) {
    this.listItemTargets.forEach(currentLi => {
      delete currentLi.dataset.selected;
    });

    li.dataset.selected = 'true';
    return li;
  }

  toggleItemSelection(li) {
    if (li.dataset.selected === 'true') {
      delete li.dataset.selected;
    }
    else {
      li.dataset.selected = 'true';
    }
  }

  selectItemRange(li) {
    const items = this.listItemTargets;
    if (!items || items.length === 0) {
      return;
    }

    const anchor = this.anchorItem || this.getSelectedItem() || li;
    const anchorIndex = items.indexOf(anchor);
    const currentIndex = items.indexOf(li);
    if (anchorIndex === -1 || currentIndex === -1) {
      this.selectSingleItem(li);
      return;
    }

    const from = Math.min(anchorIndex, currentIndex);
    const to = Math.max(anchorIndex, currentIndex);

    items.forEach((currentLi, index) => {
      if (from <= index && index <= to) {
        currentLi.dataset.selected = 'true';
      }
      else {
        delete currentLi.dataset.selected;
      }
    });
  }

  fireSelectionChanged(focusedItem = null) {
    const selectedItems = Array.from(this.getSelectedItems());
    const selected = selectedItems.length > 0 ? selectedItems[0] : null;

    fireChangeSelectedLiEvent(this.element, {
      selected,
      selectedItems,
      focusedItem,
    });
  }


  detectLiFrom(elem) {
    return elem.closest('li');
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