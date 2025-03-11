import { Controller } from "@hotwired/stimulus";
import { getCsrfToken } from 'lib/schema'

export default class extends Controller {
  static targets = ['navigationPane', 'subscriptionsPane', 'articlesPane', 'contentsPane', 'linkEditSubscription'];
  static values = {
    adaptSubscriptionsController: String, // 接続する Subscriotions コントローラの識別子
    adaptArticlesController: String, // 接続する Articles コントローラの識別子
  }

  connect() {
    // それぞれの Pane は、クリックされることで "focus" のマークがつくようにします。
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

  // 指定した pane をフォーカス状態にします（ "focus" をマークします）。
  // その他の pane(s) のフォーカス状態は外されます。
  focusPane(pane) {
    this.allPaneTargets().forEach((pane) => pane.classList.remove('focused'));
    pane.classList.add('focused');
  }

  // keyup LEFT on articles pane
  backToSubscriptionsPane(evt) {
    this.focusPane(this.subscriptionsPaneTarget);
    this.subscriptionsController().setFocusToCurrentItem();
  }

  // keyup RIGHT on subscriptions pane
  forwardToArticlesPane(evt) {
    this.focusPane(this.articlesPaneTarget);

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
    this.focusPane(this.articlesPaneTarget);
    this.articlesController().activateFirstUnreadItem();
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
