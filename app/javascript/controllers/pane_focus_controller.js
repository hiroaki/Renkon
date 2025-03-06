import { Controller } from "@hotwired/stimulus";
import { getCsrfToken } from 'lib/schema'

export default class extends Controller {
  static targets = ['navigationPane', 'subscriptionsPane', 'articlesPane', 'contentsPane', 'linkEditSubscription'];
  static values = {
    adaptSubscriptionsController: String, // 接続する Subscriotions コントローラの識別子
    adaptArticlesController: String, // 接続する Articles コントローラの識別子
  }

  connect() {
    // それぞれの Pane は、クリックされることで "forcus" のマークがつくようにします。
    // これは GUI の focus とは異なり、単に focus された要素がどの Pane の中ににあるか、の判定のみに使えます。
    // このマークは CSS の装飾のために用いています。どの具体的な要素に focus があるかは別にコントロールしておく必要があります。
    this.allPaneTargets().forEach((pane) => {
      pane.addEventListener('click', () => this.focusPane(pane));
    });

    // initialize state for Edit subscription button
    this.#resetEditSubscriptionLinkBySubscriptionListItem(this.getSelectedSubscriptionListItem());
  }

  // INTERFACE of subscriptionsController inherited SelectedLiBaseController
  subscriptionsController() {
    const controllerElement = this.subscriptionsPaneTarget.querySelector(`[data-controller="${this.adaptSubscriptionsControllerValue}"]`);

    if (controllerElement) {
      return controllerElement.selectedLi;
    } else {
      // not connected (loaded) yet
      return null;
    }
  }

  // INTERFACE of articlesController inherited SelectedLiBaseController
  articlesController() {
    const controllerElement = this.articlesPaneTarget.querySelector(`[data-controller="${this.adaptArticlesControllerValue}"]`);

    if (controllerElement) {
      return controllerElement.selectedLi;
    } else {
      // not connected (loaded) yet
      return null;
    }
  }

  // 選択されている Subscription 項目があればそれを返します。なければ null です。
  getSelectedSubscriptionListItem() {
    const controller = this.subscriptionsController();
    if (controller) {
      return controller.getSelectedItem();
    } else {
      return null;
    }
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
    this.focusPane(this.subscriptionsPaneTarget);

    const selectedSubscription = this.getSelectedSubscriptionListItem();
    if (selectedSubscription) {
      selectedSubscription.focus();
    } else {
      debugger; // something wrong
    }
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
    const controller = this.subscriptionsController();
    if (controller) {
      controller.refreshItem(evt.target.dataset['subscription']);
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
