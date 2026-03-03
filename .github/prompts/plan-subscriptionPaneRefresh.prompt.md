## Plan: 購読削除後の購読ペイン更新（改訂）

今回の改訂では、まず削除導線の不一致を先に解消し、そのうえで destroy の応答を Turbo 主導に整理して購読ペインのみを更新します。これにより、全画面リロードを避けつつ、実装の見通しと保守性を両立します。方針は「最小変更で安定化 → 部分更新の責務整理」で、既存のモーダル運用は維持します。削除後は購読一覧を再描画し、削除対象が選択中だった場合は右ペインをクリアして不整合を防ぎます。

**Steps**
1. 削除イベント名の不一致を先に修正し、削除導線を一本化する（[app/views/subscriptions/index.html.erb](app/views/subscriptions/index.html.erb)、[app/javascript/controllers/subscriptions_controller.js](app/javascript/controllers/subscriptions_controller.js)）。
2. destroy の Turbo 応答を明示し、購読一覧フレーム全体を更新できる形にする（[app/controllers/subscriptions_controller.rb](app/controllers/subscriptions_controller.rb)）。
3. 購読一覧の再描画責務を分離し、destroy 成功時に購読ペインを更新する stream テンプレート/部分テンプレートを追加する（[app/views/subscriptions/index.html.erb](app/views/subscriptions/index.html.erb)、[app/views/subscriptions](app/views/subscriptions)）。
4. モーダルは現行方針どおり「開いたまま成功表示」を維持しつつ、一覧更新と競合しないよう表示責務を整理する（[app/views/subscriptions/destroy.html.erb](app/views/subscriptions/destroy.html.erb)、[app/views/subscriptions/edit.html.erb](app/views/subscriptions/edit.html.erb)）。
5. 削除対象が選択中だったケースで articles/contents をクリアし、編集導線を無効化する連携を追加する（[app/javascript/controllers/pane_focus_controller.js](app/javascript/controllers/pane_focus_controller.js)）。
6. 既存の削除系システムテストに「一覧から対象が消える」「右ペイン整合が保たれる」を追加する（[spec/system/subscriptions_spec.rb](spec/system/subscriptions_spec.rb)）。

**Verification**
- bundle exec rspec spec/system/subscriptions_spec.rb:217
- bundle exec rspec spec/system/subscriptions_spec.rb
- 必要に応じて削除関連の最小範囲を個別実行して回帰確認

**Decisions**
- 全画面リロードは採用しない
- 購読ペインのみ更新する
- モーダルは開いたまま成功表示
- 先行タスクとして削除イベント名不一致の修正を追加
