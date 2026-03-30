import { Controller } from "@hotwired/stimulus";
import { buildInsertContextHref } from 'lib/pane_focus_link_urls';
import { syncContentsPaneBySelectedArticles } from 'lib/pane_focus_contents_sync';
import { setPaneFocusEditLinkState } from 'lib/pane_focus_action_links';
import { clearPaneFocusStatusMessage, showPaneFocusStatusMessage } from 'lib/pane_focus_status';

export default class extends Controller {
  static outlets = ['subscriptions', 'articles'];
  static targets = ['navigationPane', 'subscriptionsPane', 'articlesPane', 'contentsPane', 'linkNewSubscription', 'linkNewGroup', 'linkEdit', 'buttonMarkSelectedRead', 'buttonMarkSelectedUnread', 'buttonMoveSelectedToTrash', 'statusArea', 'statusText', 'statusIdle'];

  connect() {
    // それぞれの Pane は、その範囲の要素がクリックされることで "focused" のマークがつくようにします。
    // これはブラウザの focus とは別の概念で、 focus された要素がどの Pane の中にあるかの判定のみに使えるもので、
    // このマークは CSS の装飾の制御に用いています。
    // ブラウザの focus の操作は別にコントロールする必要があります。
    this.allPaneTargets().forEach(pane => {
      pane.addEventListener('click', () => this.setCurrentPane(pane));
    });

    // initialize state for Edit subscription button
    this.#syncSubscriptionAndGroupActions(this.getSelectedSubscriptionListItem());
    this.updateBulkReadButtons([]);
    this.lastFocusedArticleItem = null;
    this.clearStatusMessage();

    //
    this.observeArticlePaneChanges();
  }

  disconnect() {
    // 記事ペイン監視の後始末
    console.log('PaneFocusController.observerForArticlePane.disconnect()');
    this.observerForArticlePane.disconnect();
  }

  // "記事" ペインの内容変更を検出し、記事選択に依存する UI（contents / 一括既読ボタン）をリセットします。
  observeArticlePaneChanges() {
    this.observerForArticlePane = new MutationObserver((mutationsList, observer) => {
      for (let mutation of mutationsList) {
        if (mutation.type === 'childList' && mutation.removedNodes.length > 0) {
          for (const removedNode of mutation.removedNodes) {
            if (removedNode.nodeType === Node.ELEMENT_NODE) {
              this.resetArticleDependentUi();
              break;
            }
          }
        }
      }
    });

    // DOM の削除があるのは turbo-frame の中なため、監視対象の直接の子要素だけで済むように turob-frame にセットしています。
    this.observerForArticlePane.observe(this.articlesPaneTarget.querySelector('turbo-frame'), {
      childList: true
    });
  }

  // INTERFACE of subscriptionsController inherited SelectedLiBaseController
  subscriptionsController() {
    return this.hasSubscriptionsOutlet ? this.subscriptionsOutlet : null;
  }

  // INTERFACE of articlesController inherited SelectedLiBaseController
  articlesController() {
    return this.hasArticlesOutlet ? this.articlesOutlet : null;
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

  // このコントローラが操作する pane の全てのリスト
  allPaneTargets() {
    return [this.navigationPaneTarget, this.subscriptionsPaneTarget, this.articlesPaneTarget, this.contentsPaneTarget];
  }

  // 指定した pane に "focused" をマークします。
  // その他の pane(s) の "focused" は外されます。
  setCurrentPane(pane) {
    this.allPaneTargets().forEach(pane => pane.classList.remove('focused'));
    pane.classList.add('focused');
  }

  isCurrentPane(pane) {
    return pane.classList.contains('focused');
  }

  // keyup LEFT on articles pane
  backToSubscriptionsPane(evt) {
    this.setCurrentPane(this.subscriptionsPaneTarget);
    this.subscriptionsController().setFocusToCurrentItem();
  }

  // keyup RIGHT on subscriptions pane
  forwardToArticlesPane(evt) {
    this.setCurrentPane(this.articlesPaneTarget);

    const controller = this.articlesController();
    const selectedItems = controller.getSelectedItems();
    if (0 < selectedItems.length) {
      controller.moveFocusToItem(selectedItems.item(selectedItems.length - 1));
    }
    else {
      controller.activateFirstItem();
    }
  }

  // keyup SPACE on subscriptions pane
  forwardToUnreadArticlePane(evt) {
    this.setCurrentPane(this.articlesPaneTarget);
    this.articlesController().activateFirstUnreadItem();
  }

  // keyup SPACE on articles pane or contents pane
  async forwardContentsOrNextArticle(evt) {
    if (this.isCurrentPane(this.contentsPaneTarget)) {
      // コンテンツペインにフォーカスがある場合、記事リストペインへ戻してから処理を続けます。
      this.setCurrentPane(this.articlesPaneTarget);
      this.articlesController()?.setFocusToCurrentItem();
    } else if (!this.isCurrentPane(this.articlesPaneTarget)) {
      return;
    }

    const controller = this.articlesController();
    if (!controller) {
      return;
    }

    const selectedItems = Array.from(controller.getSelectedItems());
    const anchorItem = this.resolveSpaceActionAnchorItem(controller, selectedItems);

    // contents ペインに、現在選択している Article のコンテンツが表示されている場合、
    // それがまだスクロール可能ならばスクロールだけを行います。
    // スクロールが最後まで到達しているならば、次の Article を "選択状態" にするための処理へ続きます。
    if (selectedItems.length > 0) {
      const contentsPane = this.contentsPaneTarget;
      const maxScroll = contentsPane.scrollHeight - contentsPane.clientHeight;
      if (contentsPane.scrollTop + 1 < maxScroll) {
        contentsPane.scrollBy({ top: contentsPane.clientHeight, behavior: 'auto' });
        return false;
      }
    }

    await controller.markItemsRead(selectedItems);

    const nextUnread = this.findNextUnreadAfter(controller, anchorItem);
    if (nextUnread) {
      controller.activateItem(nextUnread);
    }
  }

  resolveSpaceActionAnchorItem(controller, selectedItems) {
    if (selectedItems.length === 0) {
      return null;
    }

    if (this.lastFocusedArticleItem && selectedItems.includes(this.lastFocusedArticleItem)) {
      return this.lastFocusedArticleItem;
    }

    return selectedItems[selectedItems.length - 1];
  }

  findNextUnreadAfter(controller, currentItem) {
    const articles = controller.listItemTargets;
    const currentPos = currentItem ? articles.indexOf(currentItem) : -1;

    // 次の "未読" 項目をアクティブにします。
    for (let i = currentPos + 1; i < articles.length; ++i) {
      if (articles[i].dataset['unread'] === 'true') {
        return articles[i];
      }
    }

    return null;
  }

  // "既読状況" に変化があった時、購読リストの当該項目を更新します（未読数バッジの更新）
  onChangeReadStatus(evt) {
    const controller = this.subscriptionsController();
    if (controller) {
      controller.refreshItem(evt.target.dataset['subscription']);
    }
  }

  // 選択されている "購読" が変わった時、操作バー上の「編集」ボタンの操作対象を当該購読の内容に変更します。
  onChangeSelectedSubscriptionListItem(evt) {
    const li = evt.detail.selected;
    this.#syncSubscriptionAndGroupActions(li);
  }

  onChangeSelectedArticleListItems(evt) {
    const selectedItems = evt.detail.selectedItems || [];
    const focusedItem = evt.detail.focusedItem || null;
    this.lastFocusedArticleItem = selectedItems.includes(focusedItem)
      ? focusedItem
      : selectedItems[selectedItems.length - 1] || null;

    this.updateBulkReadButtons(selectedItems);
    this.syncContentsPaneBySelectedArticles(selectedItems);
  }

  updateBulkReadButtons(selectedItems) {
    const hasSelectedArticles = selectedItems.length > 0;
    this.buttonMarkSelectedReadTarget.disabled = !hasSelectedArticles;
    this.buttonMarkSelectedUnreadTarget.disabled = !hasSelectedArticles;
    this.buttonMoveSelectedToTrashTarget.disabled = !hasSelectedArticles;
  }

  resetArticleDependentUi() {
    this.clearContentsPane();
    this.updateBulkReadButtons([]);
    this.lastFocusedArticleItem = null;
  }

  markSelectedArticlesRead() {
    const controller = this.articlesController();
    if (controller) {
      controller.markSelectedItemsRead();
    }
  }

  markSelectedArticlesUnread() {
    const controller = this.articlesController();
    if (controller) {
      controller.markSelectedItemsUnread();
    }
  }

  moveSelectedArticlesToTrash() {
    const controller = this.articlesController();
    if (controller) {
      controller.deleteSelectedItems();
    }
  }

  syncContentsPaneBySelectedArticles(selectedItems) {
    const contentsFrame = this.getContentsFrame();
    if (!contentsFrame) {
      return;
    }
    syncContentsPaneBySelectedArticles(contentsFrame, selectedItems);
    this.contentsPaneTarget.scrollTop = 0;
  }

  getContentsFrame() {
    return this.contentsPaneTarget.querySelector('turbo-frame#contents');
  }

  #syncSubscriptionAndGroupActions(li) {
    const subscriptionEditUrl = li && li.dataset.itemType === 'subscription' ? li.dataset['urlEdit'] : null;
    const groupEditUrl = li && li.dataset.itemType === 'group' ? li.dataset['urlEdit'] : null;

    this.#resetNewSubscriptionLinkHref(li);
    this.#resetNewGroupLinkHref(li);
    // set unified edit link to either subscription or group edit url
    this.#resetEditLinkHref(subscriptionEditUrl || groupEditUrl);
  }

  #resetNewSubscriptionLinkHref(li) {
    const baseHref = this.linkNewSubscriptionTarget.dataset.baseHref || this.linkNewSubscriptionTarget.href;
    this.linkNewSubscriptionTarget.href = buildInsertContextHref(baseHref, li, window.location.origin);
  }

  #resetNewGroupLinkHref(li) {
    const baseHref = this.linkNewGroupTarget.dataset.baseHref || this.linkNewGroupTarget.href;
    this.linkNewGroupTarget.href = buildInsertContextHref(baseHref, li, window.location.origin);
  }

  #resetEditLinkHref(settingHref) {
    if (!this.hasLinkEditTarget) { return; }
    setPaneFocusEditLinkState(this.linkEditTarget, settingHref);
  }

  // "購読" または "記事" コントローラが接続されたとき。
  onConnectedSelectedLiBaseController(evt) {
    let controller_id = evt.detail.identifier;
    let controller = controller_id === 'subscriptions' ? this.subscriptionsController() : this.articlesController();
    console.log("connectedSelectedLiBaseController", controller_id, controller);
  }

  // "ゴミ箱" が空にされたとき、 "購読リスト" で選択されている項目が "ゴミ箱" である場合に限り、
  // "コンテンツ" ペインと "記事リスト" ペインをクリアします。
  onEmptyTrash(evt) {
    const selectedSubscription = this.getSelectedSubscriptionListItem();
    if (selectedSubscription && selectedSubscription.id === 'trash') {
      this.clearContentsPane();
      this.clearArticlesPane();
    }
  }

  clearArticlesPane() {
    this.articlesPaneTarget.querySelector('turbo-frame#articles').innerHTML = '';
    this.resetArticleDependentUi();
  }

  clearContentsPane() {
    const frame = this.getContentsFrame();
    if (frame) {
      frame.innerHTML = '';
    }
  }

  onStatusError(evt) {
    const message = evt?.detail?.message || "Couldn't save the new order. Please try again.";
    showPaneFocusStatusMessage(this.statusAreaTarget, this.statusTextTarget, this.statusIdleTarget, message);
  }

  onSubscriptionsRefreshed(_evt) {
    const selected = this.getSelectedSubscriptionListItem();
    if (!selected || selected.dataset.itemType !== 'subscription') {
      return;
    }

    const subscriptionId = selected.dataset.subscription;
    if (!subscriptionId) {
      return;
    }

    const controller = this.subscriptionsController();
    if (!controller) {
      return;
    }

    controller.reloadArticlesPaneBySubscriptionId(subscriptionId);
  }

  clearStatusMessage() {
    if (!this.hasStatusAreaTarget || !this.hasStatusTextTarget || !this.hasStatusIdleTarget) {
      return;
    }

    clearPaneFocusStatusMessage(this.statusAreaTarget, this.statusTextTarget, this.statusIdleTarget);
  }
}
