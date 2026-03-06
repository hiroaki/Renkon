import SelectedLiBaseController from 'lib/selected_li_base_controller'
import TurboFrameDelegator from 'lib/turbo_frame_delegator'
import { getCsrfToken } from 'lib/schema'

class RefreshSubscriptionDelegator extends TurboFrameDelegator {
  // override
  prepareRequest(request) {
    super.prepareRequest(request);
    console.log('request', request);

    if (!request.isSafe) {
      const token = getCsrfToken();
      if (token) {
        request.headers['X-CSRF-Token'] = token
      }
    }
  }
}

export default class extends SelectedLiBaseController {
  connect() {
    super.connect();
    this.fireSelectionChanged(this.getSelectedItem());
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
    if (!this.isSubscriptionItem(li)) {
      return;
    }

    const message = li.dataset.textForConfirmDestroy || 'Sure?';
    if (!confirm(message)) {
      evt.stopImmediatePropagation();
    }
  }

  // Subscription の削除処理をリクエストします。
  async destroySubscription(evt) {
    const li = this.detectLiFrom(evt.target);
    if (!this.isSubscriptionItem(li)) {
      return;
    }

    const url = li.dataset['urlDestroy'];

    try {
      const response = await fetch(url, {
        method: 'DELETE',
        headers: { 'X-CSRF-Token': getCsrfToken() }
      });

      if (response.ok) {
        // 選択状態であった <li> を remove するので、選択状態がなくなった（変化した）ことを通知します。
        // イベントを dispatch する要素 li を先に remove してしまうと通知できなくなるため、
        // イベントを通知してから削除してます。
        // 他の（上層の）要素で dispatch して通知を送ればよいのですが、
        // どの要素が適切かの見極めができていないため、とりあえずの処置です。
        const event = new CustomEvent('changeSelectedLi', {
          detail: { selected: null },
          bubbles: true,
        });
        li.dispatchEvent(event);
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
    if (!this.isSubscriptionItem(li)) {
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
        const event = new CustomEvent('changeSelectedLi', {
          detail: { selected: null },
          bubbles: true,
        });
        li.dispatchEvent(event);
        li.remove();
      }
      else {
        console.error('Failed to delete the subscription', response);
      }
    })
    .catch(error => console.error('Error:', error));
  }

  async refreshItem(id) {
    const li = this.element.querySelector(`li[data-subscription="${id}"]`);
    if (!this.isSubscriptionItem(li)) {
      return;
    }

    const turboFrame = li.querySelector('turbo-frame');
    if (turboFrame) {
      const delegator = new RefreshSubscriptionDelegator(
        li.dataset['urlRefresh'], 'PATCH', turboFrame.id, new URLSearchParams({ short: true, dry_run: true })
      );
      await delegator.perform();
    }
  }

  isSubscriptionItem(li) {
    return !!li && li.dataset.itemType === 'subscription';
  }
}
