import SelectedLiBaseController from "lib/selected_li_base_controller"
import { getCsrfToken } from 'lib/schema'
import { fireChangeReadStatusEvent } from 'lib/pane_focus_events'

export default class extends SelectedLiBaseController {
  connect() {
    super.connect();
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

  async markSelectedItemsRead() {
    await this.updateSelectedItemsUnreadStatus(false);
  }

  async markSelectedItemsUnread() {
    await this.updateSelectedItemsUnreadStatus(true);
  }

  async updateSelectedItemsUnreadStatus(targetUnread) {
    const selectedItems = Array.from(this.getSelectedItems());
    if (selectedItems.length === 0) {
      return;
    }

    for (const li of selectedItems) {
      await this.updateUnreadStatus(li, targetUnread);
    }
  }

  async updateUnreadStatus(li, targetUnread) {
    const currentUnread = li.dataset.unread == 'true';
    if (currentUnread === targetUnread) {
      return true;
    }

    const url = li.dataset[targetUnread ? 'urlUnread' : 'urlRead'];
    if (!url) {
      console.warn('Read status URL is missing', { targetUnread, li });
      return false;
    }

    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: { 'X-CSRF-Token': getCsrfToken() }
      });

      if (response.ok) {
        li.dataset.unread = targetUnread ? 'true' : 'false';
        const button = li.querySelector('button');
        if (button) {
          this.resetReadStatus(button);
        }
        fireChangeReadStatusEvent(li);
        return true;
      }

      console.error('Failed to update read status', response);
      console.warn('Read status request returned non-ok response', { url, targetUnread, status: response.status });
      return false;
    } catch (error) {
      console.error('Error:', error);
      console.warn('Read status request threw an exception', { url, targetUnread, error });
      return false;
    }
  }

  //
  async deleteItem(evt) {
    await this.deleteSelectedItems(evt);
  }

  async deleteSelectedItems(evt) {
    const deleteTargets = this.collectDeleteTargets(evt);
    if (deleteTargets.length === 0) {
      return;
    }

    const nextFocusTarget = this.detectPostDeleteFocusTarget(deleteTargets);
    const deletedItems = await this.disableSelectedItems(deleteTargets);
    deletedItems.forEach(li => li.remove());

    if (nextFocusTarget && this.element.contains(nextFocusTarget)) {
      this.activateItem(nextFocusTarget);
    }
    else {
      this.fireSelectionChanged(null);
    }
  }

  collectDeleteTargets(evt) {
    const selectedItems = Array.from(this.getSelectedItems());
    if (selectedItems.length > 0) {
      return selectedItems;
    }

    const li = this.detectLiFrom(evt.target);
    return li ? [li] : [];
  }

  detectPostDeleteFocusTarget(deleteTargets) {
    const allItems = this.listItemTargets;
    const deletingSet = new Set(deleteTargets);
    const deletingIndexes = deleteTargets
      .map(li => allItems.indexOf(li))
      .filter(index => index !== -1);

    if (deletingIndexes.length === 0) {
      return null;
    }

    const firstDeletingIndex = Math.min(...deletingIndexes);
    for (let i = firstDeletingIndex; i < allItems.length; ++i) {
      if (!deletingSet.has(allItems[i])) {
        return allItems[i];
      }
    }

    for (let i = firstDeletingIndex - 1; 0 <= i; --i) {
      if (!deletingSet.has(allItems[i])) {
        return allItems[i];
      }
    }

    return null;
  }

  async disableSelectedItems(deleteTargets) {
    const deletedItems = [];
    for (const li of deleteTargets) {
      const disabled = await this.disableItem(li);
      if (disabled) {
        deletedItems.push(li);
      }
    }

    return deletedItems;
  }

  async disableItem(li) {
    const request = this.buildDeleteRequest(li);
    if (!request) {
      console.warn('Failed to build delete request', { li });
      return false;
    }

    const { method, url } = request;
    if (!url) {
      console.warn('Delete URL is missing', { method, li });
      return false;
    }

    try {
      const response = await fetch(url, {
        method,
        headers: { 'X-CSRF-Token': getCsrfToken() }
      });

      if (response.ok) {
        fireChangeReadStatusEvent(li);
        return true;
      } else {
        console.error('Failed to delete the item', response);
        console.warn('Delete request returned non-ok response', { method, url, status: response.status });
        return false;
      }
    } catch (error) {
      console.error('Error:', error);
      console.warn('Delete request threw an exception', { method, url, error });
      return false;
    }
  }

  buildDeleteRequest(li) {
    const isDisabledItem = li.dataset['disabled'] === 'true';
    if (isDisabledItem) {
      return {
        method: 'DELETE',
        url: li.dataset['urlDestroy'],
      };
    }

    return {
      method: 'PATCH',
      url: li.dataset['urlDisable'],
    };
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
