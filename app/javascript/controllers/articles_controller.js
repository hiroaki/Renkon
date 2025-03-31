import SelectedLiBaseController from "lib/selected_li_base_controller"
import { getCsrfToken } from 'lib/schema'
import { fireConnectArticlesEvent, fireChangeReadStatusEvent } from 'lib/pane_focus_events'

export default class extends SelectedLiBaseController {
  connect() {
    super.connect();

    // NOTE: アイテムリストが取り除かれた時、どちらかといえば disconnect 時に（イベントを bubble-up して）、
    // pane-controller に取り除かれたことを検知してもらいたいところですが、
    // disconnect 時この要素は既に無くなっているためここでイベントを作っても、それが伝播しません。
    // 要素が取り除かれたことを祖先要素で検知するには祖先要素の方で MutationObserver の実装を検討してください。
    fireConnectArticlesEvent(this.element);
  }

  //
  handlerMakeItemRead(evt) {
    const li = this.detectLiFrom(evt.target);
    this.makeItemRead(li);
  }

  makeItemRead(li) {
    if (li.dataset['unread'] == 'true') {
      const targetElement = li.querySelector('button');
      this.toggleReadStatus(li).then(() => {
        this.resetReadStatus(targetElement);
      });
    }
  }

  //
  resetReadStatus(targetElement) {
    const li = targetElement.closest('li');
    targetElement.textContent = li.dataset.unread == 'true' ? '●' : '　';
  }

  //
  handlerToggleReadStatus(evt) {
    const targetElement = evt.currentTarget;
    const li = targetElement.closest('li');
    this.toggleReadStatus(li).then(() => {
      this.resetReadStatus(targetElement);
    });
  }

  async toggleReadStatus(li) {
    const isUnread = li.dataset.unread == 'true';
    const url = li.dataset[isUnread ? 'urlRead' : 'urlUnread'];

    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: { 'X-CSRF-Token': getCsrfToken() }
      });

      if (response.ok) {
        li.dataset.unread = isUnread ? 'false' : 'true';
        fireChangeReadStatusEvent(li);
      } else {
        console.error('Failed to update read status', response);
      }
    } catch (error) {
      console.error('Error:', error);
    }
  }

  //
  async deleteItem(evt) {
    const li = this.detectLiFrom(evt.target);
    const url = li.dataset['urlDisable'];

    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: { 'X-CSRF-Token': getCsrfToken() }
      });

      if (response.ok) {
        fireChangeReadStatusEvent(li);
        li.remove();
      } else {
        console.error('Failed to delete the item', response);
      }
    } catch (error) {
      console.error('Error:', error);
    }
  }

  //
  activateFirstUnreadItem() {
    // 選択されている <li> があればその位置から最初の未読のものを、または
    // 選択されている <li> がなければ先頭から最初の未読のものを、選択状態にします。
    const articles = this.listItemTargets;
    let pos = -1;
    for (let i = 0; i < articles.length; ++i) {
      if (articles[i].dataset['selected'] == 'true') {
        pos = i;
        break;
      }
    }

    for (let i = pos + 1; i < articles.length; ++i) {
      let li = articles[i];
      if (li.dataset['unread'] == 'true') {
        // call a method of articles controller (based selected-li controller)
        this.activateItem(li);
        break;
      }
    }
  }
}
