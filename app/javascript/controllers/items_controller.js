import SelectedLiBaseController from "lib/selected_li_base_controller"

export default class extends SelectedLiBaseController {
  selectUnreadItem(evt) {
    const items = document.getElementById('items').querySelectorAll('li');

    // items ペイン上からこのイベントが発生している場合は、
    // 現在の選択位置以降から未読を探すようにします（ channels ペインでは先頭から）
    let pos = -1;
    for (let i = 0; i < items.length; ++i) {
      if (items[i] == evt.currentTarget) {
        pos = i;
        break;
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
    const li = evt.currentTarget;

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
    const isUnread = li.dataset.unread == 'true';
    const url = li.dataset[ isUnread ? 'urlRead' : 'urlUnread' ];

    return fetch(url, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name=csrf-token]').content
      }
    })
    .then(response => {
      // TODO: channels pane にある当該チャンネルの未読カウンター（バッヂ）の更新
      if (response.ok) {
        if (isUnread) {
          li.dataset.unread = 'false';
        }
        else {
          li.dataset.unread = 'true';
        }
      }
      else {
        console.error('Failed to update read status');
      }
    })
    .catch(error => console.error('Error:', error));
  }
}
