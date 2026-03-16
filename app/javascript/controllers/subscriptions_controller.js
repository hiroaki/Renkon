import SelectedLiBaseController from 'lib/selected_li_base_controller'
import RefreshDelegator from 'lib/refresh_delegator'
import { getCsrfToken } from 'lib/schema'
import { fireChangeSelectedLiEvent, fireStatusErrorEvent } from 'lib/pane_focus_events'

export default class extends SelectedLiBaseController {
  connect() {
    super.connect();
    this.restoreGroupCollapseState();
    this.fireSelectionChanged(this.getSelectedItem());
  }

  toggleGroupCollapse(evt) {
    evt.preventDefault();
    evt.stopPropagation();

    const button = evt.currentTarget;
    const li = button.closest('li[data-item-type="group"][data-group-id]');
    if (!li) {
      return;
    }

    const collapsed = li.dataset.collapsed === 'true';
    this.setGroupCollapsed(li, !collapsed, true);
  }

  openUrl(evt) {
    const li = this.detectLiFrom(evt.target);
    if (!this.isSubscriptionItem(li)) {
      return;
    }

    super.openUrl(evt);
  }

  // Subscription の削除処理の前提として、この確認の動作を発動させるイベントに続いて、
  // 実際の destroy の処理へ進むイベントが、連続して仕込まれていることが期待されています。
  // その前提のもと、 confirm が No を返したときは、 destroy へ進むことをキャンセルするために
  // stopImmediatePropagation を呼び出すことにしています。
  confirmDestroy(evt) {
    const li = this.detectLiFrom(evt.target);
    if (!this.isDestroyableItem(li)) {
      return;
    }

    const message = li.dataset.textForConfirmDestroy || 'Sure?';
    if (!confirm(message)) {
      evt.stopImmediatePropagation();
    }
  }

  // 選択中アイテム（購読/グループ）の削除処理をリクエストします。
  async destroySelectedItem(evt) {
    const li = this.detectLiFrom(evt.target);
    if (!this.isDestroyableItem(li)) {
      return;
    }

    const url = li.dataset['urlDestroy'];

    try {
      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': getCsrfToken(),
          'X-Requested-With': 'XMLHttpRequest',
        }
      });

      if (response.ok) {
        // 選択状態であった <li> を remove するので、選択状態がなくなった（変化した）ことを通知します。
        // イベントを dispatch する要素 li を先に remove してしまうと通知できなくなるため、
        // イベントを通知してから削除してます。
        // 他の（上層の）要素で dispatch して通知を送ればよいのですが、
        // どの要素が適切かの見極めができていないため、とりあえずの処置です。
        fireChangeSelectedLiEvent(li, { selected: null });
        li.remove();
      } else {
        console.error('Failed to delete the subscription', response);
      }
    } catch (error) {
      console.error('Error:', error);
    }
  }

  _destroySubscription(evt) {
    const li = this.detectLiFrom(evt.target);
    if (!this.isDestroyableItem(li)) {
      return;
    }

    const url = li.dataset['urlDestroy'];

    return fetch(url, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': getCsrfToken() }
    })
    .then(response => {
      if (response.ok) {
        // 選択状態であった <li> を remove するので、選択状態がなくなった（変化した）ことを通知します。
        // イベントを dispatch する要素 li を先に remove してしまうと通知できなくなるため、
        // イベントを通知してから削除してます。
        // 他の（上層の）要素で dispatch して通知を送ればよいのですが、
        // どの要素が適切かの見極めができていないため、とりあえずの処置です。
        fireChangeSelectedLiEvent(li, { selected: null });
        li.remove();
      }
      else {
        console.error('Failed to delete the subscription', response);
      }
    })
    .catch(error => console.error('Error:', error));
  }

  selectBySubscriptionId(id) {
    return this.activateItemBySelector(`li[data-item-type="subscription"][data-subscription="${id}"]`)
  }

  reloadArticlesPaneBySubscriptionId(id) {
    const li = this.element.querySelector(`li[data-item-type="subscription"][data-subscription="${id}"]`)
    if (!li) {
      return false
    }

    // Ignore links from nested descendant items and use only this row's navigation URL.
    const span = Array.from(li.querySelectorAll('span[data-link-to-url]'))
      .find((candidate) => candidate.closest('li') === li)
    const url = span?.dataset['linkToUrl']
    const frameId = span?.dataset['linkToFrame']
    const frame = frameId ? document.querySelector(`turbo-frame[id=${frameId}]`) : null

    if (!url || !frame) {
      return false
    }

    // Force reload even when URL did not change.
    frame.removeAttribute('src')
    frame.src = url
    return true
  }

  async refreshItem(id, options = {}) {
    const li = this.element.querySelector(`li[data-subscription="${id}"]`);
    if (!this.isSubscriptionItem(li)) {
      return;
    }

    const performFetch = options.performFetch ?? false;
    const showStatusError = options.showStatusError ?? false;
    const refreshUrl = options.refreshUrl || (performFetch ? li.dataset['urlRefresh'] : li.dataset['urlRow']);
    const method = options.method || (performFetch ? 'PATCH' : 'GET');

    const turboFrame = li.querySelector('turbo-frame');
    if (!turboFrame || !refreshUrl) {
      return false;
    }

    const delegator = new RefreshDelegator(
      refreshUrl,
      method,
      turboFrame.id
    );
    await delegator.perform();

    if (delegator.failed && showStatusError) {
      const details = await delegator.getFailureDetails();
      fireStatusErrorEvent(window, details.message);
    }

    return !delegator.failed;
  }

  isSubscriptionItem(li) {
    return !!li && li.dataset.itemType === 'subscription';
  }

  isGroupItem(li) {
    return !!li && li.dataset.itemType === 'group';
  }

  isDestroyableItem(li) {
    return this.isSubscriptionItem(li) || this.isGroupItem(li);
  }

  restoreGroupCollapseState() {
    this.listItemTargets
      .filter((li) => this.isGroupItem(li))
      .forEach((li) => {
        const key = this.collapseStorageKey(li.dataset.groupId);
        const stored = window.localStorage.getItem(key);
        if (stored === null) {
          return;
        }

        this.setGroupCollapsed(li, stored === 'true', false);
      });
  }

  setGroupCollapsed(li, collapsed, persist) {
    li.dataset.collapsed = collapsed ? 'true' : 'false';

    const nested = li.querySelector(':scope > ul[data-tree-sort-list]');
    if (nested) {
      nested.hidden = collapsed;
    }

    const button = li.querySelector(':scope > div .group-collapse-toggle');
    if (button) {
      button.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
    }

    const icon = li.querySelector(':scope > div [data-collapse-icon]');
    if (icon) {
      icon.textContent = collapsed ? '▸' : '▾';
    }

    if (persist && li.dataset.groupId) {
      window.localStorage.setItem(this.collapseStorageKey(li.dataset.groupId), collapsed ? 'true' : 'false');
    }
  }

  collapseStorageKey(groupId) {
    return `renkon.groupCollapsed.${groupId}`;
  }
}
