import { Controller } from "@hotwired/stimulus";
import { getCsrfToken } from 'lib/schema'

export default class extends Controller {
  static targets = ['navigationPane', 'subscriptionsPane', 'articlesPane', 'contentsPane', 'linkEditSubscription'];
  static values = {
    adaptSubscriptionsController: String, // 接続する Subscriotions コントローラの識別子
    adaptArticlesController: String, // 接続する Articles コントローラの識別子
  }

  connect() {
    // それぞれの Pane は、その範囲の要素がクリックされることで "focused" のマークがつくようにします。
    // これはブラウザの focus とは別の概念で、 focus された要素がどの Pane の中にあるかの判定のみに使えるもので、
    // このマークは CSS の装飾の制御に用いています。
    // ブラウザの focus の操作は別にコントロールする必要があります。
    this.allPaneTargets().forEach((pane) => {
      pane.addEventListener('click', () => this.setCurrentPane(pane));
    });

    // initialize state for Edit subscription button
    this.#resetEditSubscriptionLinkBySubscriptionListItem(this.getSelectedSubscriptionListItem());
  }

  // INTERFACE of subscriptionsController inherited SelectedLiBaseController
  subscriptionsController() {
    const identifier = this.adaptSubscriptionsControllerValue;
    const controllerElement = this.subscriptionsPaneTarget.querySelector(`[data-controller="${identifier}"]`);

    if (controllerElement) {
      return controllerElement[identifier];
    } else {
      // not connected (loaded) yet
      return null;
    }
  }

  // INTERFACE of articlesController inherited SelectedLiBaseController
  articlesController() {
    const identifier = this.adaptArticlesControllerValue;
    const controllerElement = this.articlesPaneTarget.querySelector(`[data-controller="${identifier}"]`);

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
    return [this.navigationPaneTarget, this.subscriptionsPaneTarget, this.articlesPaneTarget, this.contentsPaneTarget]
  }

  // 指定した pane に "focused" をマークします。
  // その他の pane(s) の "focused" は外されます。
  setCurrentPane(pane) {
    this.allPaneTargets().forEach((pane) => pane.classList.remove('focused'));
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
        if (articles[i] == li) {
          pos = i;
          break;
        }
      }
    }
    const isSomeArticleActivated = pos != -1;

    // contents ペインに、現在選択している Article のコンテンツが表示されている場合、
    // それがまだスクロール可能ならばスクロールだけを行います。
    // スクロールが最後まで到達しているならば、次の Article を "選択状態" にするための処理へ続きます。
    if (isSomeArticleActivated) {
      const contentsPane = this.contentsPaneTarget;
      const maxScroll = contentsPane.scrollHeight - contentsPane.clientHeight;
      if (contentsPane.scrollTop + 1 < maxScroll) {
        contentsPane.scrollBy({top: contentsPane.clientHeight, behavior: 'auto'});
        return false;
      }
    }

    // 次の "未読" 項目をアクティブにします。
    for (let i = pos + 1; i < articles.length; ++i) {
      if (articles[i].dataset['unread'] == 'true') {
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

  // "記事" リストが変更されたとき、 "コンテンツ" ペインをクリアします。
  onConnectArticles(evt) {
    this.clearContentsPane();
  }

  // "ゴミ箱" が空にされたとき、 "購読リスト" で選択されている項目が "ゴミ箱" である場合に限り、
  // "コンテンツ" ペインと "記事リスト" ペインをクリアします。
  onEmptyTrash(evt) {
    const selectedSubscription = this.getSelectedSubscriptionListItem();
    if (selectedSubscription && selectedSubscription.id == 'trash') {
      this.clearContentsPane();
      this.clearArticlesPane();
    }
  }

  clearArticlesPane() {
    this.articlesPaneTarget.querySelector('turbo-frame#articles').innerHTML = '';
  }

  clearContentsPane() {
    this.contentsPaneTarget.querySelector('turbo-frame#contents').innerHTML = '';
  }
}
