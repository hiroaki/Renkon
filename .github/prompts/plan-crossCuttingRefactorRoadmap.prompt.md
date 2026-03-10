## Plan: Cross-Cutting Refactor Roadmap

今後の拡張に備えて、まずは責務分離を進める計画にします。
機能は極力変えず、フェーズごとに小さく分けて検証・コミットしていく方針です。

**Steps**
1. フェーズ1: JavaScript基盤の分離（低リスク）
2. `app/javascript/lib/pane_focus_events.js` のイベント名と payload 契約を定数化し、dispatch ヘルパー導入。
3. `app/javascript/controllers/pane_focus_controller.js` から純粋ロジック（リンクURL算出など）を `lib` に抽出。
4. `pane_focus` の contents 同期処理（frame map/create/show/hide）を専用モジュールへ分離。
5. フェーズ2: Rails controller のサービス化（中リスク）
6. `app/controllers/articles_controller.rb` の bulk 処理本体を `app/services/articles/` へ抽出。
7. `app/controllers/subscriptions_controller.rb` の `reorder_tree` 検証ロジックを `app/services/subscriptions/` へ抽出。
8. フェーズ3: View と spec の保守性向上（低リスク）
9. `app/views/articles/_list.html.erb` の `data-*` 生成を `app/helpers/articles_helper.rb` に集約。
10. `spec/requests/articles/` の JSON 検証重複を共通ヘルパー化。
11. フェーズ4: 回帰検証と段階導入
12. 各フェーズごとに対象spec＋手動確認を実施し、通過単位で小コミット。
13. 特に Delete 押しっぱなし、contents 切替、DnD 永続化を重点再確認。

**Relevant files**
- `app/javascript/controllers/pane_focus_controller.js` — 分割対象の中心
- `app/javascript/lib/pane_focus_events.js` — イベント契約一元化
- `app/javascript/lib/` — 新規分離モジュール配置先
- `app/controllers/articles_controller.rb` — bulk service 抽出対象
- `app/controllers/subscriptions_controller.rb` — reorder validation 抽出対象
- `app/services/articles/` — 新規 service
- `app/services/subscriptions/` — 新規 service
- `app/views/articles/_list.html.erb` — data属性簡素化対象
- `app/helpers/articles_helper.rb` — data属性生成集約
- `spec/requests/articles/bulk_operations_spec.rb` — bulk API回帰
- `spec/system/articles_bulk_delete_spec.rb` — Delete押しっぱなし回帰
- `spec/system/articles_bulk_read_unread_spec.rb` — bulk既読未読回帰
- `spec/system/subscriptions_sortable_spec.rb` — reorder回帰

**Verification**
1. フェーズ1後
`bundle exec rspec spec/system/articles_bulk_delete_spec.rb spec/system/articles_bulk_read_unread_spec.rb`
2. フェーズ2後
`bundle exec rspec spec/requests/articles/bulk_operations_spec.rb spec/requests/subscriptions/reorder_spec.rb`
3. フェーズ3後
`bundle exec rspec spec/requests/articles spec/system/articles_*`
4. 手動確認
Delete押しっぱなし、記事選択時の contents 更新、DnD 後の再読み込み整合

**Decisions**
- 機能追加より前に責務分離を優先
- フェーズ単位で小さくコミット
- controller を薄くし、API契約は維持
- 一気に大規模リライトはしない

**Session Handoff Notes**
- 新しい AI セッションで進めて問題ありません（推奨）。このファイルを最初に読ませれば継続可能です。
- 実装作業ブランチ（現在）: `improve-delete-key-repeat-ux`
- 直近コミット（この計画に関係するもの）:
	- `5dfedde` `Extract bulk article client utilities`
	- `7f43276` `Cap delete key repeat queue to one pending action`
	- `e5169da` `Serialize article delete key repeat without duplicate requests`
	- `25c9315` `Handle stale article show requests after rapid deletes`
	- `1f7511b` `Route article pane actions through bulk APIs`
	- `1db1bd2` `Add bulk article read-status and delete APIs`
- `develop` には未取り込みのコミットがあるため、着手時は `git branch --show-current` と `git log --oneline -n 10` で位置確認すること。
- この計画ファイル自体は未コミットの可能性があるため、必要なら先に計画専用コミットを作ること。
- 着手前の推奨確認コマンド:
	- `bundle exec rspec spec/system/articles_bulk_delete_spec.rb spec/system/articles_bulk_read_unread_spec.rb`
	- `bundle exec rspec spec/requests/articles/bulk_operations_spec.rb`
	- `bundle exec rspec spec/requests/articles/show_spec.rb`
- 既知の注意点:
	- 連続削除の入力処理は「実行中 + 予約1件」に制限済み。さらなる高速化は別タスクとして扱う。
	- `ArticlesController#show` は stale Turbo Frame リクエスト時に `204` を返す仕様。
