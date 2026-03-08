## Plan: Group Collapse Toggle UX

グループ行の左側に専用トグルボタンを置き、クリックで折りたたみ/展開だけを行う。グループ名クリックは従来どおり「選択のみ」に限定し、誤操作を防ぐ。折りたたみ状態は `localStorage` に保存し、リロード後も復元する。

**Steps**
1. フェーズ1: DOM構造の分離
2. `app/views/subscriptions/_group_node.html.erb` で、グループ見出しを「トグルボタン」と「選択用ラベル」の2要素に分離する。トグルは左側固定、ラベルは `click->subscriptions#handlerEnterItem` のみを維持。*基礎変更*
3. グループ `<li>` に `data-collapsed` を持たせ、ネスト `<ul>` は `data-tree-sort-list` のまま維持する。*depends on 2*
4. フェーズ2: 挙動実装（選択との分離）
5. `app/javascript/controllers/subscriptions_controller.js` に `toggleGroupCollapse` を追加し、`event.stopPropagation()`/`event.preventDefault()` で選択イベント伝播を遮断する。*depends on 2*
6. 同コントローラ `connect()` で `localStorage` からグループごとの折りたたみ状態を復元し、トグル時に保存する。保存キー例: `renkon.groupCollapsed.<groupId>`。*depends on 5*
7. フェーズ3: スタイル調整
8. `app/assets/stylesheets/application.tailwind.css` に折りたたみ用スタイルを追加する。`data-collapsed="true"` 時は子 `<ul>` を非表示化（必要なら `max-height` + transition）し、トグルアイコンは開閉状態に応じて回転。*depends on 3,5*
9. アニメーションは軽量に限定し、複雑なら無効化できる構造で実装する。*parallel with 8*
10. フェーズ4: DnD整合
11. 折りたたみ状態でもグループ自体のドラッグは維持し、子要素へのD&Dは展開時のみ可能とする（仕様化）。`subscriptions_tree_sort_controller.js` は基本変更なし。*depends on 8*
12. フェーズ5: テスト
13. system spec を追加し、以下を検証する:
14. トグルクリックで開閉が切り替わること
15. トグルクリック時にグループが選択状態にならないこと
16. グループ名クリック時は選択のみ行われること
17. リロード後に折りたたみ状態が復元されること（localStorage）
18. 既存の Sortable/選択系spec を再実行し回帰確認。*depends on 11*

**Relevant files**
- `app/views/subscriptions/_group_node.html.erb` — トグルボタンの追加、ラベルと責務分離。
- `app/javascript/controllers/subscriptions_controller.js` — 折りたたみトグル、伝播抑止、localStorage保存/復元。
- `app/assets/stylesheets/application.tailwind.css` — 折りたたみ表示とアイコン状態のスタイル。
- `app/javascript/controllers/subscriptions_tree_sort_controller.js` — 影響確認のみ（必要時のみ微調整）。
- `spec/system/subscriptions_selection_spec.rb` — 選択分離回帰（拡張候補）。
- `spec/system/subscriptions_sortable_spec.rb` — DnD回帰確認。
- `spec/system/`（新規spec） — 開閉/復元の挙動テスト追加先。

**Verification**
1. `bundle exec rspec spec/system/subscriptions_selection_spec.rb spec/system/subscriptions_sortable_spec.rb` を実行。
2. 追加した折りたたみspecを実行し、トグル/選択分離/復元が通ることを確認。
3. 手動確認: トグルクリックでは選択が変わらず、グループ名クリックでは開閉せず選択のみになること。
4. 手動確認: 折りたたみ後にページを再読み込みして状態が維持されること。

**Decisions**
- 採用: 折りたたみトリガーは左側ボタンのみ。グループ名では開閉しない。
- 採用: 折りたたみ状態は `localStorage` で保持。
- 採用: アニメーションは軽量（任意）。まずは操作正確性優先。
- 非採用: 開閉操作をグループ選択クリックに兼用するUI。
