## Plan: Sortable導入前の購読リスト整備

Sortable + 階層化の前段として、一覧描画責務の分離、順序の正規化、データ属性の一般化、テスト基盤の補強を先に実施する。これにより、後続のD&D実装は「UIイベントを保存APIへ接続する作業」に集中できる状態を作る。

**Steps**
1. フェーズ1: 描画責務の分離（`short`依存の解消）
2. `app/views/subscriptions/_subscription.html.erb` の二重責務を分割し、サイドバー行表示専用 partial（例: `_subscription_row.html.erb`）と詳細表示専用 partial（例: `_subscription_detail.html.erb`）へ分離する。*以降のDOM属性整理の前提*
3. `app/views/subscriptions/index.html.erb` と `app/views/subscriptions/show.html.erb` の呼び出し側を更新し、表示用途ごとに partial を使い分ける。`params[:short]` 分岐を一覧行描画から排除する。
4. フェーズ2: 順序の単一ソース化（永続化準備）
5. `subscriptions` に `position`（必要なら次段で `parent_id` 追加に拡張しやすい設計）を追加するマイグレーションを作成し、既存レコードへ初期値をバックフィルする。*depends on 1-3*
6. `Subscription` の一覧取得を明示的な並び順に統一する（例: `position ASC, id ASC`）。`Subscription.all_with_count_articles` で order を明示し、コントローラ側の取得経路を一本化する。
7. フェーズ3: 一覧件数取得の整理（N+1回避）
8. `Subscription.all_with_count_articles` が返す集計列（例: `unread_count`）をビューで利用し、`app/views/subscriptions/_subscription_row.html.erb` から `subscription.count_articles(unread: true)` の都度計算を除去する。*parallel with 5-6 だが、最終統合は 6 完了後*
9. 既存 `count_articles` は詳細表示や他箇所で必要か確認し、不要なら縮小、必要なら用途を限定してコメントを付ける。
10. フェーズ4: リスト項目データ属性の一般化（group混在準備）
11. `app/views/subscriptions/index.html.erb` の各 `li` に `data-item-type` を導入（`trash` / `subscription`）。将来 `group` を同列で追加できる属性設計にする。*depends on 1-3*
12. `app/javascript/controllers/subscriptions_controller.js` の操作（open/edit/destroy/refresh）を item-type ベースでガードし、subscription専用操作が `trash` や将来の `group` に誤適用されないようにする。
13. 同時に `index` 内の `link_to link_to` の不整合を解消し、DOM構造を単純化してD&D判定を安定させる。
14. フェーズ5: テスト基盤の先行補強
15. `spec/models/subscription_spec.rb` に、明示 order と集計列利用の期待値を追加する。重複している `describe '.all_with_count_articles'` は統合して意図を明確化する。*depends on 5-8*
16. `spec/requests/subscriptions` 系の新規specを追加し、一覧取得の並び順、将来追加する並び替えAPIの受け皿としての基本失敗系（不正パラメータ時）を先に固定する。*parallel with 15*
17. `spec/system/subscriptions_spec.rb` は最小限の回帰確認（一覧表示・編集導線）に留め、D&D本体のsystemテストは次フェーズ（Sortable導入）へ分離する。
18. フェーズ6: Sortable導入準備の完了判定
19. 以下を満たすことを「前準備完了」のDefinition of Doneとする。
20. `subscriptions` 一覧描画に `params[:short]` 分岐が残っていない。
21. 一覧順序が `position` 基準で安定し、テストで担保されている。
22. 一覧行の未読件数が集計列ベースで表示される。
23. `li` が item-type を持ち、controller が type に応じて安全に処理分岐する。
24. 基本spec（model/request/system）の回帰が通過している。

**Relevant files**
- `app/views/subscriptions/_subscription.html.erb` — 分割元。責務分離の起点。
- `app/views/subscriptions/index.html.erb` — リストDOM、data属性、link不整合修正。
- `app/views/subscriptions/show.html.erb` — 詳細表示partialへの接続。
- `app/models/subscription.rb` — 集計クエリと明示 order、件数取得責務。
- `app/controllers/subscriptions_controller.rb` — 取得経路統一。
- `app/javascript/controllers/subscriptions_controller.js` — item-typeガードと操作分岐。
- `db/migrate/*add_position_to_subscriptions*.rb` — position導入とバックフィル。
- `spec/models/subscription_spec.rb` — 集計・順序テスト再編。
- `spec/requests/subscriptions/*` — 一覧順序と失敗系の受け皿。
- `spec/system/subscriptions_spec.rb` — 回帰最小確認。

**Verification**
1. `bin/rails db:migrate` を実行し、既存データの `position` が欠損なく設定されることを確認する。
2. `bin/rspec spec/models/subscription_spec.rb` を実行し、集計列・並び順テストが通ることを確認する。
3. `bin/rspec spec/requests`（追加分）を実行し、一覧順序と不正入力の失敗系が期待通りであることを確認する。
4. `bin/rspec spec/system/subscriptions_spec.rb` を実行し、一覧表示・編集導線の回帰がないことを確認する。
5. 手動で `root_path` を開き、購読一覧の表示順・未読バッジ・trash操作・編集導線が従来通り動くことを確認する。

**Decisions**
- 今回のスコープは「Sortable導入前整備」に限定し、実際のD&D UIと並び替え保存API実装は次フェーズに分離する。
- データモデルはまず `position` 導入を優先し、`group`/`parent_id` の本導入は次フェーズで行う（差分を小さく保つため）。
- UI変更は既存見た目を維持し、DOMと責務整理を優先する。

**Further Considerations**
1. `position` の採番方式: 連番密詰め（1,2,3...）を採用し、将来のD&D保存時に再採番コストを許容する方針でよいか。推奨: まず連番。
2. request spec の粒度: 次フェーズで追加する reorder APIを見据えて、`/subscriptions` の一覧順保証だけ先に固定するか、先行で `reorder` ルート雛形まで作るか。推奨: 先に一覧順保証のみ。
3. `count_articles` の残し方: 互換維持で残すか、一覧用途から切り離して用途限定メソッドに改名するか。推奨: 一旦残してコメントで用途限定。
