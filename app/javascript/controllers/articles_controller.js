import SelectedLiBaseController from "lib/selected_li_base_controller"
import { fireChangeReadStatusEvent, fireStatusErrorEvent } from 'lib/pane_focus_events'
import { groupItemsByUrl, indexItemsByArticleId, requestBulkOperation } from 'lib/articles_bulk_client'

export default class extends SelectedLiBaseController {
  connect() {
    super.connect();
    this.deleteRequestInFlight = false;
    this.deleteRequestQueued = false;
  }

  //
  handlerMakeItemRead(evt) {
    const li = this.detectLiFrom(evt.target);
    this.makeItemRead(li);
  }

  async makeItemRead(li) {
    if (li.dataset['unread'] == 'true') {
      await this.updateItemsUnreadStatus([li], false);
    }
  }

  //
  resetReadStatus(targetElement) {
    const li = targetElement.closest('li');
    targetElement.textContent = li.dataset.unread == 'true' ? '●' : '　';
  }

  //
  async handlerToggleReadStatus(evt) {
    evt.preventDefault();
    const targetElement = evt.currentTarget;
    const li = targetElement.closest('li');
    await this.toggleReadStatus(li);
  }

  async toggleReadStatus(li) {
    const targetUnread = li.dataset.unread !== 'true';
    await this.updateItemsUnreadStatus([li], targetUnread);
  }

  async markSelectedItemsRead() {
    await this.markItemsRead(Array.from(this.getSelectedItems()));
  }

  async markItemsRead(items) {
    const targetItems = Array.isArray(items) ? items.filter(Boolean) : [];
    if (targetItems.length === 0) {
      return;
    }

    await this.updateItemsUnreadStatus(targetItems, false);
  }

  async markSelectedItemsUnread() {
    await this.updateSelectedItemsUnreadStatus(true);
  }

  async toggleSelectedItemsReadStatus() {
    const selectedItems = Array.from(this.getSelectedItems());
    if (selectedItems.length === 0) {
      return;
    }

    const areAllSelectedItemsUnread = selectedItems.every(li => li.dataset.unread == 'true');
    if (areAllSelectedItemsUnread) {
      await this.markSelectedItemsRead();
      return;
    }

    await this.markSelectedItemsUnread();
  }

  async updateSelectedItemsUnreadStatus(targetUnread) {
    const selectedItems = Array.from(this.getSelectedItems());
    if (selectedItems.length === 0) {
      return;
    }

    await this.updateItemsUnreadStatus(selectedItems, targetUnread);
  }

  async updateItemsUnreadStatus(items, targetUnread) {
    const actionableItems = items.filter((li) => li.dataset.unread === (targetUnread ? 'false' : 'true'));
    if (actionableItems.length === 0) {
      return;
    }

    const groups = groupItemsByUrl(actionableItems, 'urlBulkUpdateReadStatus');
    const subscriptionEventSources = new Map();
    let errorMessage = null;

    const requests = Array.from(groups.entries()).map(async ([url, groupedItems]) => {
      if (!url) {
        console.warn('Bulk read-status URL is missing', { targetUnread, groupedItems });
        return;
      }

      const itemById = indexItemsByArticleId(groupedItems);
      const response = await requestBulkOperation(url, {
        article_ids: Array.from(itemById.keys()),
        target_unread: targetUnread,
      });

      if (!response.ok) {
        errorMessage ||= response.errorMessage;
        return;
      }

      const succeededIds = Array.isArray(response.data?.succeeded_ids) ? response.data.succeeded_ids : [];
      succeededIds.forEach((articleId) => {
        const li = itemById.get(Number(articleId));
        if (!li) {
          return;
        }

        li.dataset.unread = targetUnread ? 'true' : 'false';
        const button = li.querySelector('button');
        if (button) {
          this.resetReadStatus(button);
        }

        const subscriptionId = li.dataset.subscription;
        if (subscriptionId && !subscriptionEventSources.has(subscriptionId)) {
          subscriptionEventSources.set(subscriptionId, li);
        }
      });
    });

    await Promise.all(requests);
    if (errorMessage) {
      fireStatusErrorEvent(window, errorMessage);
    }
    this.fireChangeReadStatusBySubscription(subscriptionEventSources);
  }

  //
  async deleteItem(evt) {
    await this.deleteSelectedItems(evt);
  }

  async deleteSelectedItems(evt) {
    if (this.deleteRequestInFlight) {
      // Keep at most one queued delete request while current request is in flight.
      this.deleteRequestQueued = true;
      return;
    }

    this.deleteRequestInFlight = true;
    try {
      await this.performDeleteSelectedItems(evt);
    } finally {
      this.deleteRequestInFlight = false;

      if (this.deleteRequestQueued) {
        this.deleteRequestQueued = false;
        // Continue hold-to-delete behavior without overlapping requests.
        void this.deleteSelectedItems();
      }
    }
  }

  async performDeleteSelectedItems(evt) {
    const deleteTargets = this.collectDeleteTargets(evt);
    if (deleteTargets.length === 0) {
      return;
    }

    const nextFocusTarget = this.detectPostDeleteFocusTarget(deleteTargets);
    const deletedItems = await this.bulkDeleteItems(deleteTargets);
    deletedItems.forEach(li => li.remove());

    if (nextFocusTarget && this.element.contains(nextFocusTarget)) {
      this.activateItem(nextFocusTarget);
      this.anchorItem = nextFocusTarget;
    }
    else {
      this.anchorItem = null;
      this.fireSelectionChanged(null);
    }
  }

  collectDeleteTargets(evt) {
    const selectedItems = Array.from(this.getSelectedItems());
    if (selectedItems.length > 0) {
      return selectedItems;
    }

    if (!evt || !evt.target) {
      return [];
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

  async bulkDeleteItems(items) {
    const groups = groupItemsByUrl(items, 'urlBulkDelete');
    const deletedItems = [];
    const subscriptionEventSources = new Map();
    let errorMessage = null;

    const requests = Array.from(groups.entries()).map(async ([url, groupedItems]) => {
      if (!url) {
        console.warn('Bulk delete URL is missing', { groupedItems });
        return;
      }

      const itemById = indexItemsByArticleId(groupedItems);
      const response = await requestBulkOperation(url, {
        article_ids: Array.from(itemById.keys()),
      });

      if (!response.ok) {
        errorMessage ||= response.errorMessage;
        return;
      }

      const succeededIds = Array.isArray(response.data?.succeeded_ids) ? response.data.succeeded_ids : [];
      succeededIds.forEach((articleId) => {
        const li = itemById.get(Number(articleId));
        if (!li) {
          return;
        }

        deletedItems.push(li);
        const subscriptionId = li.dataset.subscription;
        if (subscriptionId && !subscriptionEventSources.has(subscriptionId)) {
          subscriptionEventSources.set(subscriptionId, li);
        }
      });
    });

    await Promise.all(requests);
    if (errorMessage) {
      fireStatusErrorEvent(window, errorMessage);
    }
    this.fireChangeReadStatusBySubscription(subscriptionEventSources);
    return deletedItems;
  }

  fireChangeReadStatusBySubscription(subscriptionEventSources) {
    subscriptionEventSources.forEach((li) => {
      fireChangeReadStatusEvent(li);
    });
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
