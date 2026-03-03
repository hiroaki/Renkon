## Plan: 選択記事の一括既読・未読ボタン追加

上部ナビゲーションに「Mark Read」「Mark Unread」の2ボタンを追加し、記事リストの複数選択集合に対して既存 `read/unread` API を1件ずつ適用します。未選択時はボタンを押せない状態にし、Trash表示中でも有効のまま動作させます。実装責務は、UI状態管理を [app/javascript/controllers/pane_focus_controller.js](app/javascript/controllers/pane_focus_controller.js)、実処理を [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js) に分け、既存の選択イベント連携（`changeSelectedLi`）と未読バッジ更新連携（`changeReadStatus`）を再利用します。

**Steps**
1. 上部ボタンを追加  
   [app/views/subscriptions/main.html.erb](app/views/subscriptions/main.html.erb) のナビに「Mark Read」「Mark Unread」ボタンを追加し、初期状態を disabled にする。`pane-focus` の action/target を割り当てて状態制御の受け口を作る。
2. 選択件数でボタン活性を制御  
   [app/javascript/controllers/pane_focus_controller.js](app/javascript/controllers/pane_focus_controller.js) に、記事選択変更時（既存 `onChangeSelectedArticleListItems`）に選択件数を見て2ボタンを enable/disable する処理を追加する。
3. 一括既読/未読の呼び出し経路を追加  
   [app/javascript/controllers/pane_focus_controller.js](app/javascript/controllers/pane_focus_controller.js) から `articlesController()` を通じて `markSelectedItemsRead` / `markSelectedItemsUnread`（新規）を呼ぶメソッドを追加する。
4. 記事コントローラに一括処理を実装  
   [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js) に以下を追加する。  
   - `markSelectedItemsRead()` / `markSelectedItemsUnread()`  
   - 共通内部処理（選択集合取得、逐次PATCH、成功分の `data-unread` 更新、ドット表示更新）  
   - 失敗時は既存方針に合わせてログ出力（best-effort）
5. 既存イベント連携を維持  
   一括更新成功時に既存 `fireChangeReadStatusEvent` を各対象 `li` で発火し、購読リストの未読数バッジ更新連鎖（pane-focus → subscriptions refresh）を保つ。
6. UI文言・状態の整合を確認  
   ボタンラベル、disabled時の見た目、Trash表示時の可用性が仕様どおりであることを確認する（Trashでも有効）。
7. system spec を追加/更新  
   [spec/system/home_page_spec.rb](spec/system/home_page_spec.rb) へボタン存在確認を追加し、必要に応じて新規specで以下を検証する。  
   - 未選択時はボタン押下不可  
   - 複数選択で一括既読/未読が反映  
   - 購読バッジ更新が維持される  
   - Trash表示でも同様に動作

**Verification**
- System spec 実行（関連）:  
  - [spec/system/home_page_spec.rb](spec/system/home_page_spec.rb)  
  - 追加する一括既読/未読spec（新規）  
  - 既存の複数選択/contents関連spec（回帰確認）
- 手動確認:  
  - 通常一覧で複数選択 → Mark Read / Mark Unread  
  - 未選択時の disabled 状態  
  - Trash一覧で同操作  
  - 失敗時ログ出力と成功分のみ反映（best-effort）

**Decisions**
- 未選択時: ボタンは押せない状態にする
- Trash表示時: ボタンは有効のまま
- API方式: 既存 `read/unread` を1件ずつ呼ぶ（bulk APIは作らない）
