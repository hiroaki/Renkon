import SelectedLiBaseController from "lib/selected_li_base_controller"
import { getCsrfToken } from 'lib/schema'
import { fireConnectItemsEvent, fireChangeReadStatusEvent } from 'lib/pane_focus_events'

export default class extends SelectedLiBaseController {
  connect() {
    super.connect();

    // NOTE: アイテムリストが取り除かれた時、どちらかといえば disconnect 時に（イベントを bubble-up して）、
    // pane-controller に取り除かれたことを検知してもらいたいところですが、
    // disconnect 時この要素は既に無くなっているためここでイベントを作っても、それが伝播しません。
    // 要素が取り除かれたことを祖先要素で検知するには祖先要素の方で MutationObserver の実装を検討してください。
    fireConnectItemsEvent(this.element)
  }

  selectUnreadItem(evt) {
    const li = this.detectLiFrom(evt.target)
    const items = document.getElementById('items').querySelectorAll('li');

    // items ペイン上からこのイベントが発生している場合は、
    // 現在の選択位置以降から未読を探すようにします（ channels ペインでは先頭から）
    let pos = -1;
    for (let i = 0; i < items.length; ++i) {
      if (items[i] == li) {
        pos = i;
        break;
      }
    }
    const isFiredOnItem = pos != -1;

    if (isFiredOnItem) {
      const contentsPane = document.getElementById('contents-pane');
      const maxScroll = contentsPane.scrollHeight - contentsPane.clientHeight;
      if (contentsPane.scrollTop + 1 < maxScroll) {
        contentsPane.scrollBy({top: contentsPane.clientHeight, behavior: 'auto'});
        return false;
      }
    }

    for (let i = pos + 1; i < items.length; ++i) {
      if (items[i].dataset['unread'] == 'true') {
        this.enterItem(items[i]);
        break;
      }
    }
  }

  //
  handlerMakeItemRead(evt) {
    const li = this.detectLiFrom(evt.target)

    if (li.dataset['unread'] == 'true') {
      const targetElement = li.querySelector('button');
      const me = this;
      this.toggleReadStatus(li)
      .then(() => {
        me.resetReadStatus(targetElement);
      });
    }
  }

  //
  resetReadStatus(targetElement) {
    const li = targetElement.closest('li');
    if (li.dataset.unread == 'true') {
       targetElement.textContent = '●'
    } else {
      targetElement.textContent = '　'
    }
  }

  //
  handlerToggleReadStatus(evt) {
    const targetElement = evt.currentTarget;
    const li = targetElement.closest('li');
    const me = this;
    this.toggleReadStatus(li)
    .then(() => {
      me.resetReadStatus(targetElement);
    });
  }

  toggleReadStatus(li) {
    const me = this;
    const isUnread = li.dataset.unread == 'true';
    const url = li.dataset[ isUnread ? 'urlRead' : 'urlUnread' ];

    return fetch(url, {
      method: 'PATCH',
      headers: { 'X-CSRF-Token': getCsrfToken() }
    })
    .then(response => {
      if (response.ok) {
        li.dataset.unread = isUnread ? 'false' : 'true';
        fireChangeReadStatusEvent(li);
      }
      else {
        console.error('Failed to update read status', response);
      }
    })
    .catch(error => console.error('Error:', error));
  }

  //
  deleteItem(evt) {
    const me = this;
    const li = this.detectLiFrom(evt.target);
    const url = li.dataset['urlDisable'];

    return fetch(url, {
      method: 'PATCH',
      headers: { 'X-CSRF-Token': getCsrfToken() }
    })
    .then(response => {
      if (response.ok) {
        fireChangeReadStatusEvent(li);
        li.remove();
      }
      else {
        console.error('Failed to delete the item', response);
      }
    })
    .catch(error => console.error('Error:', error));
  }
}
