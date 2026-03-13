## Plan: Main新規購読の即時反映と自動Refresh

main画面のモーダル作成成功時に、購読リストを即時更新し、新規項目を自動選択したうえで、その項目のRSS取得を非同期で開始する。サーバはcreate成功時にTurbo Streamで「subscriptions再描画 + modal成功表示」を返し、クライアントはsubscriptionsフレーム再読込完了を契機に新規IDを選択して単体refreshを実行する。refresh失敗時は作成成功を維持し、警告のみ表示する。

**このプランは実装完了済みです（commit: 2ae8b8a, e91047f）。以下は実施内容の記録です。**

**Steps**

Phase 0: 事前リファクタ

1. [✅ Done] Phase 0-A: refreshの委譲ロジックを軽量共通化する。refresh_controller.js と subscriptions_controller.js の Delegator 実装重複を共有モジュールに寄せ、単体refresh/一括refreshの双方で同じ失敗分類とCSRF処理を使う。*事前リファクタ A* → `app/javascript/lib/refresh_delegator.js` を新規作成。
2. [✅ Done] Phase 0-B: モーダル成功表示を show から分離する。create/update 成功モーダルを専用partialに切り出し、showテンプレートの責務を「詳細表示」と分離する。*事前リファクタ B, depends on 1* → `app/views/subscriptions/_success_modal.html.erb` を新規作成し、`show.html.erb` を更新。
3. [✅ Done] Phase 0-C: subscriptions選択APIを拡張する。SelectedLiBaseController/SubscriptionsController 側に selectById 相当の薄いAPIを追加し、作成後自動選択の意図を明示化する。*事前リファクタ C, parallel with 1-2* → `activateItemBySelector` を `selected_li_base_controller.js` に、`selectBySubscriptionId` を `subscriptions_controller.js` に追加。

Phase 1: create Turbo Stream化

4. [✅ Done] Phase 1: create成功レスポンスをTurbo Stream化する。SubscriptionsController#createでturbo_frame_request?分岐を追加し、成功時はsubscriptionsフレーム再描画とmodal成功表示を同時返却する。通常HTML遷移は既存互換で維持する。*基盤ステップ, depends on 2*
5. [✅ Done] Phase 1: create成功モーダルに作成完了データ（new subscription id、refresh endpoint、選択指示フラグ）をdata属性で埋める。後続JSがDOM再読込後に追跡できる形へ統一する。*depends on 4* → `_success_modal.html.erb` 内で `subscription-create-success` Stimulusコントローラに `data-subscription-create-success-subscription-id-value` と `data-subscription-create-success-refresh-url-value` を渡す形で実装。

Phase 2: クライアント側自動選択・refresh・記事ペイン

6. [✅ Done] Phase 2: subscriptionsフレーム再描画後の自動選択処理をStimulusに追加する。Phase 0で拡張した選択APIを使い、新規liを選択・フォーカス・編集リンク状態同期まで行う。*depends on 3,5, parallel with 7* → `subscription_create_success_controller.js` の `applyCreateFlow()` で実現。`turbo:frame-load` イベントを監視し、subscriptionsフレーム再読込完了後に `selectBySubscriptionId` を呼ぶ。
7. [✅ Done] Phase 2: 新規項目の単体refresh実行をクライアント側に追加する。Phase 0で共通化したrefreshロジックを使い、1件refresh APIへdry_runなしPATCHを送る。*depends on 1,5, parallel with 6* → `applyCreateFlow()` が `refreshItem(id, {dryRun: false, showStatusError: true})` を呼ぶ。refresh成功後は `reloadArticlesPaneBySubscriptionId` で記事ペインも更新（計画外追加: 記事ペイン整合性のため）。
8. [✅ Done] Phase 2: refresh失敗通知を「作成成功と分離」して表示する。バッジ警告 + footer status文言（既存renkon:status-error系）で通知し、モーダル成功表示は維持する。*depends on 7* → `showStatusError: true` オプションで `renkon:status-error` イベントを発火。

Phase 2（計画外）: バグ修正・記事ペイン整合

9. [✅ Done] Bug Fix: `refresh_feed` アクションの `dry_run` パラメータが文字列 `'false'` でもRuby側に `true` と解釈される問題を修正。`ActiveModel::Type::Boolean.new.cast(params[:dry_run])` で正規化。クライアント側も `dryRun=true` 時のみ `dry_run=true` を付与（`false` 時は送信しない）に統一。回帰specを `spec/requests/subscriptions/refresh_feed_spec.rb` に追加。

Phase 3（計画外）: 全件Refresh後の記事ペイン同期（イベント駆動）

10. [✅ Done] 全件Refreshボタン押下後、選択中購読の記事ペインも更新されるようにする。イベント駆動で実装: `refresh_controller.js#all()` を async化し `Promise.allSettled` で全タスク完了を待った後 `renkon:subscriptions-refreshed` カスタムイベントを発火。`pane_focus_controller.js` がwindowでイベントを受信し、選択中購読の記事ペインを `reloadArticlesPaneBySubscriptionId` で再読込。`pane_focus_events.js` に `SUBSCRIPTIONS_REFRESHED` 定数と `fireSubscriptionsRefreshedEvent` を追加。`main.html.erb` に `@window` アクション配線を追加。

Phase 4: spec（一部未達）

11. [⚠️ Partial] Phase 4: controller spec/system specを更新・追加する。作成成功後にsubscriptionsリストへ新規項目が表示されること、新規項目が選択されること、refresh APIが起動されること、refresh失敗時でも作成成功UIが保たれることを検証する。*depends on 1-8* → WebMock stubによる自動refresh検証、全件Refresh後の記事ペイン更新verificationは追加済み。Verification の 2, 3, 5, 6, 7, 9 は未spec。
12. [⚠️ Partial] Phase 4: 非Turbo経路と既存動作の回帰確認（create失敗時422、edit/update/destroyモーダル、並び順維持、insert_context適用）を行う。*depends on 1-9* → 手動確認のみ。spec化は未完了。

**Relevant files**
- app/controllers/subscriptions_controller.rb — create, refresh_feed, apply_insert_context。成功レスポンス分岐とTurbo Stream返却の主変更点。
- app/views/subscriptions/show.html.erb — 既存modal成功表示分岐。create専用success partialへ切り出した参照元。
- app/views/subscriptions/_success_modal.html.erb （新規）— create/update成功モーダルの共通partial。`subscription-create-success` コントローラのdivを埋め込む。
- app/views/subscriptions/index.html.erb — subscriptionsフレーム構造。再描画後のDOM復帰ポイント。
- app/views/subscriptions/main.html.erb — 全件Refresh後の記事ペイン同期イベント配線先。`renkon:subscriptions-refreshed@window->pane-focus#onSubscriptionsRefreshed` を追加。
- app/views/subscriptions/destroy.turbo_stream.erb — 複数フレーム更新の既存パターン（参照のみ）。
- app/controllers/groups_controller.rb — create/update/destroyのturbo_frame_request?実装パターン（参照のみ）。
- app/javascript/controllers/subscriptions_controller.js — refreshItem, 選択状態管理。`selectBySubscriptionId`, `reloadArticlesPaneBySubscriptionId` を追加。
- app/javascript/controllers/pane_focus_controller.js — 選択変更時のリンク同期、status表示。`onSubscriptionsRefreshed` ハンドラを追加。
- app/javascript/controllers/refresh_controller.js — refresh失敗分類・バッジ表示。`all()` を async化し `renkon:subscriptions-refreshed` イベント発火を追加。
- app/javascript/lib/selected_li_base_controller.js — 選択APIの基底実装。`activateItemBySelector` を追加。
- app/javascript/lib/refresh_delegator.js （新規）— refresh委譲ロジック共通化先。CSRF注入・失敗分類を実装。
- app/javascript/lib/pane_focus_events.js — `SUBSCRIPTIONS_REFRESHED` イベント定数と `fireSubscriptionsRefreshedEvent` を追加。
- app/javascript/controllers/subscription_create_success_controller.js （新規）— 作成直後の自動選択と単体refresh起動、記事ペイン再読込を担当。
- app/javascript/controllers/modal_controller.js — 成功時モーダルクローズ挙動（参照のみ）。
- app/models/concerns/factory.rb — fetch_and_merge_feed_entries_for_subscription。refreshの実処理（参照のみ）。
- spec/system/subscriptions_spec.rb — createモーダル系既存期待の更新、WebMock stub追加、全件Refresh後記事ペイン更新specの追加。
- spec/requests/subscriptions/refresh_feed_spec.rb — `dry_run='false'` 回帰specを追加。

**Verification**
1. [✅ Done] system spec: 新規作成後にsubscriptionsフレーム内に新規liが現れることを確認。
2. [⬜ Not done] system spec: create後に新規liがselected状態になること、編集リンクが新規IDを指すことを確認。
3. [⬜ Not done] request/controller spec: create(turbo_frame)成功時にturbo_streamレスポンスでsubscriptionsとmodalが更新されることを確認。
4. [✅ Done] system spec + WebMock: 作成直後に新規subscriptionのrefresh_feed PATCHが発火することを確認（WebMock stubで実装）。
5. [⬜ Not done] failure spec: refresh_feedがFeedUtils::Errorを返しても、create成功表示と新規li表示が維持されることを確認。
6. [⬜ Not done] regression: create失敗時は422でモーダル内エラーが表示されることを確認。
7. [⬜ Not done] regression: 非Turbo create（通常ページ遷移）は従来どおりshowへ遷移することを確認。
8. [✅ Done] refactor regression: 一括refresh（Refreshボタン）と単体refresh（refreshItem）が同じ失敗分類/表示挙動で動作することを確認。
9. [⬜ Not done] refactor regression: selectById相当API経由で選択した場合も、既存の選択イベント（changeSelectedLi）が従来どおり発火することを確認。
10. [✅ Done] event-driven: 全件Refresh後、選択中購読の記事ペインが更新されることをsystem specで確認。
11. [✅ Done] bug fix regression: `dry_run='false'` を送信した場合に実際にfeed取得が発火することをrequest specで確認。

**Decisions**
- refreshは同期ではなく非同期で実行する。
- refresh失敗は作成成功と切り離し、警告表示のみ行う。
- 追加後は新規項目を自動選択する。
- Success表示はモーダル内で維持する。
- refresh完了後に記事ペインも同期する（create後の単体refreshおよび全件Refresh-allの両方）。
- 全件Refresh後の記事ペイン同期はイベント駆動（`renkon:subscriptions-refreshed` CustomEvent + `@window` 配線）で実装し、コントローラ間の直接依存を避ける。

**Further Considerations**
1. 単体refreshの呼び出し主体: Option A クライアントから既存refresh_feed API呼び出し（採用） / Option B サーバでActiveJob起動。Aは即時UI反映と失敗可視化が容易、BはUI連携が弱い。
2. リスト更新方式: Option A subscriptionsフレーム全体再読込（採用） / Option B 新規ノードのみappend/insert。Aはposition混在ロジックとの整合が安全、Bは高速だが複雑化しやすい。
3. モーダルクローズタイミング: 現状維持（Closeボタン）を採用。将来の改善として自動クローズ+toastに切り替える余地あり。
