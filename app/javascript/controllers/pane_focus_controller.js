import { Controller } from "@hotwired/stimulus";
import { getCsrfToken } from 'lib/schema'

export default class extends Controller {
  static targets = ['navigationPane', 'subscriptionsPane', 'articlesPane', 'contentsPane', 'linkEditSubscription', 'buttonMarkSelectedRead', 'buttonMarkSelectedUnread'];
  static values = {
    adaptSubscriptionsController: String, // 接続する Subscriotions コントローラの識別子
    adaptArticlesController: String, // 接続する Articles コントローラの識別子
  }

  connect() {
    // それぞれの Pane は、その範囲の要素がクリックされることで "focused" のマークがつくようにします。
    // これはブラウザの focus とは別の概念で、 focus された要素がどの Pane の中にあるかの判定のみに使えるもので、
    // このマークは CSS の装飾の制御に用いています。
    // ブラウザの focus の操作は別にコントロールする必要があります。
    this.allPaneTargets().forEach(pane => {
      pane.addEventListener('click', () => this.setCurrentPane(pane));
    });

    // initialize state for Edit subscription button
    this.#resetEditSubscriptionLinkBySubscriptionListItem(this.getSelectedSubscriptionListItem());
    this.updateBulkReadButtons([]);

    //
    this.observeArticlePaneChanges();
  }

  disconnet() {
    // TODO: この処理は不要かもしれません。 #disconnect というものがあることのメモとして残しておきます。
    console.log('PaneFocusController.observerForArticlePane.disconnect()');
    this.observerForArticlePane.disconnect();
  }

  // "記事" ペインの内容の変更を検出し、処理します。現在は "コンテンツ" ペインをクリアするだけです。
  observeArticlePaneChanges() {
    this.observerForArticlePane = new MutationObserver((mutationsList, observer) => {
      for (let mutation of mutationsList) {
        if (mutation.type === 'childList' && mutation.removedNodes.length > 0) {
          for (const removedNode of mutation.removedNodes) {
            if (removedNode.nodeType === Node.ELEMENT_NODE) {
              this.clearContentsPane();
              this.updateBulkReadButtons([]);
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
    return this.getController(this.adaptSubscriptionsControllerValue);
  }

  // INTERFACE of articlesController inherited SelectedLiBaseController
  articlesController() {
    return this.getController(this.adaptArticlesControllerValue);
  }

  getController(identifier) {
    const controllerElement = this.element.querySelector(`[data-controller="${identifier}"]`);
    if (controllerElement) {
      return controllerElement[identifier];
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

  // keyup SPACE on articles pane
  forwardContentsOrNextArticle(evt) {
    if (!this.isCurrentPane(this.articlesPaneTarget)) {
      console.error('articlesPane is not the current');
      return;
    }

    const controller = this.articlesController();
    const articles = controller.listItemTargets;

    // 記事が選択されている場合、その位置以降から "未読" 項目を探すようにします。
    const li = controller.getSelectedItem();
    let pos = -1;
    if (li) {
      for (let i = 0; i < articles.length; ++i) {
        if (articles[i] === li) {
          pos = i;
          break;
        }
      }
    }
    const isSomeArticleActivated = pos !== -1;

    // contents ペインに、現在選択している Article のコンテンツが表示されている場合、
    // それがまだスクロール可能ならばスクロールだけを行います。
    // スクロールが最後まで到達しているならば、次の Article を "選択状態" にするための処理へ続きます。
    if (isSomeArticleActivated) {
      const contentsPane = this.contentsPaneTarget;
      const maxScroll = contentsPane.scrollHeight - contentsPane.clientHeight;
      if (contentsPane.scrollTop + 1 < maxScroll) {
        contentsPane.scrollBy({ top: contentsPane.clientHeight, behavior: 'auto' });
        return false;
      }
    }

    // 次の "未読" 項目をアクティブにします。
    for (let i = pos + 1; i < articles.length; ++i) {
      if (articles[i].dataset['unread'] === 'true') {
        controller.activateItem(articles[i]);
        break;
      }
    }
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
    this.#resetEditSubscriptionLinkBySubscriptionListItem(li);
  }

  onChangeSelectedArticleListItems(evt) {
    const selectedItems = evt.detail.selectedItems || [];
    this.updateBulkReadButtons(selectedItems);
    this.syncContentsPaneBySelectedArticles(selectedItems);
  }

  updateBulkReadButtons(selectedItems) {
    const hasSelectedArticles = selectedItems.length > 0;
    this.buttonMarkSelectedReadTarget.disabled = !hasSelectedArticles;
    this.buttonMarkSelectedUnreadTarget.disabled = !hasSelectedArticles;
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

  syncContentsPaneBySelectedArticles(selectedItems) {
    const contentsFrame = this.getContentsFrame();
    if (!contentsFrame) {
      return;
    }

    const selectedEntries = selectedItems
      .map(li => {
        return {
          articleId: li.dataset.articleId,
          contentUrl: li.dataset.urlContent,
        };
      })
      .filter(entry => entry.articleId && entry.contentUrl);

    const selectedIdSet = new Set(selectedEntries.map(entry => entry.articleId));

    const existingById = this.getArticleContentsFrameMap(contentsFrame);

    existingById.forEach((frame, articleId) => {
      if (!selectedIdSet.has(articleId)) {
        this.hideArticleContentsFrame(frame);
      }
    });

    selectedEntries.forEach(entry => {
      let frame = existingById.get(entry.articleId);
      if (!frame) {
        frame = this.createArticleContentsFrame(entry.articleId, entry.contentUrl);
      }
      else {
        console.debug('[contents-cache] reused', {
          articleId: entry.articleId,
          frameId: frame.id,
        });
      }

      this.showArticleContentsFrame(frame);
      contentsFrame.appendChild(frame);
    });
  }

  getContentsFrame() {
    return this.contentsPaneTarget.querySelector('turbo-frame#contents');
  }

  getArticleContentsFrameMap(contentsFrame) {
    const frames = Array.from(contentsFrame.querySelectorAll('turbo-frame[data-article-id]'));
    return new Map(frames.map(frame => [frame.dataset.articleId, frame]));
  }

  createArticleContentsFrame(articleId, contentUrl) {
    const frame = document.createElement('turbo-frame');
    frame.id = `contents-article-${articleId}`;
    frame.dataset.articleId = articleId;
    frame.dataset.cached = 'true';
    frame.src = contentUrl;
    return frame;
  }

  hideArticleContentsFrame(frame) {
    frame.hidden = true;
  }

  showArticleContentsFrame(frame) {
    frame.hidden = false;
  }

  #resetEditSubscriptionLinkBySubscriptionListItem(li) {
    const urlEdit = li ? li.dataset['urlEdit'] : null;
    this.#resetEditSubscriptionLinkHref(urlEdit);
  }

  #resetEditSubscriptionLinkHref(settingHref) {
    if (settingHref == null) {
      this.linkEditSubscriptionTarget.href = '#';
      this.linkEditSubscriptionTarget.dataset['disabled'] = true;
    }
    else {
      this.linkEditSubscriptionTarget.href = settingHref;
      this.linkEditSubscriptionTarget.dataset['disabled'] = false;
    }
  }

  // "購読" または "記事" コントローラが接続されたとき。
  onConnectedSelectedLiBaseController(evt) {
    let controller_id = evt.detail.identifier;
    let controller = this.getController(controller_id);
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
    this.updateBulkReadButtons([]);
  }

  clearContentsPane() {
    const frame = this.getContentsFrame();
    if (frame) {
      frame.innerHTML = '';
    }
  }
}
