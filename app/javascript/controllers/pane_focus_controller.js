import { Controller } from "@hotwired/stimulus";
import TurboFrameDelegator from "lib/turbo_frame_delegator"
import { getCsrfToken } from 'lib/schema'

class RefreshSubscriptionDelegator extends TurboFrameDelegator {
  // override
  prepareRequest(request) {
    super.prepareRequest(request)
    console.log('request', request)

    if (!request.isSafe) {
      const token = getCsrfToken()
      if (token) {
        request.headers['X-CSRF-Token'] = token
      }
    }
  }
}

export default class extends Controller {
  static targets = ['navigationPane', 'subscriptionsPane', 'articlesPane', 'contentsPane', 'linkEditSubscription'];

  connect() {
    this.allPaneTargets().forEach((pane) => {
      pane.addEventListener('click', () => this.focusPane(pane));
    });

    // initialize state for Edit subscription button
    this.#resetEditSubscriptionLinkBySubscriptionListItem(this.getSelectedSubscriptionListItem())
  }

  getSelectedSubscriptionListItem() {
    return this.subscriptionsPaneTarget.querySelector('li[data-selected="true"]');
  }

  getSubscriptionListItemById(subscriptionId) {
    return this.subscriptionsPaneTarget.querySelector('li[data-subscription="'+ subscriptionId +'"]');
  }

  // 何らかのアクションが発生する要素が存在する pane の全てのリスト
  allPaneTargets() {
    return [this.navigationPaneTarget, this.subscriptionsPaneTarget, this.articlesPaneTarget, this.contentsPaneTarget]
  }

  focusPane(pane) {
    this.allPaneTargets().forEach((pane) => pane.classList.remove('focused'));
    pane.classList.add('focused');
  }

  // keyup LEFT on articles pane
  backToSubscriptionsPane(evt) {
    this.focusPane(this.subscriptionsPaneTarget)
    this.getSelectedSubscriptionListItem().focus()
  }

  // keyup RIGHT on subscriptions pane
  forwardToArticlesPane(evt) {
    this.focusPane(this.articlesPaneTarget);

    const selectedItems = this.articlesPaneTarget.querySelectorAll('li[data-selected="true"]');
    if (0 < selectedItems.length) {
      selectedItems.item(selectedItems.length - 1).focus();
    }
    else {
      const li = this.articlesPaneTarget.querySelectorAll('li').item(0);
      if (li) {
        li.closest('ul').selectedLi.enterItem(li);
      }
    }
  }

  // keyup SPACE on subscriptions pane
  forwardToUnreadArticlePane(evt) {
    this.focusPane(this.articlesPaneTarget);

    // Articles リストの、
    // 現在選択されている li がなければ先頭から最初の未読、
    // または選択されている li があればその位置から最初の未読のものを選択状態にします。
    const articles = this.articlesPaneTarget.querySelectorAll('li');
    let pos = -1;
    for (let i = 0; i < articles.length; ++i) {
      if (articles[i] == evt.currentTarget) {
        pos = i;
        break;
      }
    }

    for (let i = pos + 1; i < articles.length; ++i) {
      let li = articles[i];
      if (li.dataset['unread'] == 'true') {
        // call a method of articles controller (based selected-li controller)
        li.closest('ul').selectedLi.enterItem(li);
        break;
      }
    }
  }

  onChangeReadStatus(evt) {
    const li = this.getSubscriptionListItemById(evt.target.dataset['subscription']);
    const turboFrame = li.querySelector('turbo-frame');
    if (turboFrame) {
      new RefreshSubscriptionDelegator(
        li.dataset['urlRefresh'], 'PATCH', turboFrame.id, new URLSearchParams({short: true, dry_run: true})
      )
      .perform();
    }
  }

  onChangeSelectedSubscriptionListItem(evt) {
    const li = evt.detail.selected
    this.#resetEditSubscriptionLinkBySubscriptionListItem(li);
  }

  #resetEditSubscriptionLinkBySubscriptionListItem(li) {
    let settingHref = null;
    if (li) {
      const urlEdit = li.dataset['urlEdit']
      if (urlEdit) {
         settingHref = urlEdit;
      }
    }
    this.#resetEditSubscriptionLinkHref(settingHref)
  }

  #resetEditSubscriptionLinkHref(settingHref) {
    if (settingHref == null) {
      this.linkEditSubscriptionTarget.href = '#'
      this.linkEditSubscriptionTarget.dataset['disabled'] = true
    }
    else {
      this.linkEditSubscriptionTarget.href = settingHref
      this.linkEditSubscriptionTarget.dataset['disabled'] = false
    }
  }

  onConnectItems(evt) {
    this.clearContentsPane();
  }

  onEmptyTrash(evt) {
    const selectedSubscription = this.getSelectedSubscriptionListItem();
    if (selectedSubscription && selectedSubscription.id == 'trash') {
      this.clearContentsPane();
      this.clearItemsPane();
    }
  }

  clearItemsPane() {
    this.articlesPaneTarget.querySelector('turbo-frame#articles').innerHTML = '';
  }

  clearContentsPane() {
    this.contentsPaneTarget.querySelector('turbo-frame#contents').innerHTML = '';
  }
}
