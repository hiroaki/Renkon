## Plan: Backspaceで複数記事をゴミ箱へ

現状の単一削除は、`keydown.backspace->articles#deleteItem` がイベントターゲット由来の1件だけを処理し、続く `selectNextItem` が選択集合を1件化してしまう設計が原因です。今回の方針は、既存の member `disable` API を選択件数ぶん呼ぶ最小改修で、成功分のみ反映（best-effort）にします。削除後は「削除範囲の次項目を1件選択」に統一し、Trash画面の Backspace 挙動は今回は現状維持に留めます。これにより、実装リスクを抑えつつ、期待どおり「選択中すべてをゴミ箱へ」を実現します。

**Steps**
1. Backspaceイベントの責務整理  
   [app/views/articles/_list.html.erb](app/views/articles/_list.html.erb) の `keydown.backspace` バインドを、単一削除+単一選択遷移から「複数削除専用ハンドラ」へ切り替える（`deleteItem`/`selectNextItem` 直列実行を解消）。
2. 複数削除ハンドラ追加  
   [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js) に `deleteSelectedItems`（仮称）を追加し、`getSelectedItems()` の集合を取得して `data-url-disable` を順次 `PATCH` する。  
   - 成功: 該当 `li` をDOMから除去  
   - 失敗: その `li` は残す（best-effort）
3. 削除後フォーカス再計算  
   [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js) で削除前のDOM位置を基準に、削除範囲の次項目を1件選択（なければ前項目、なければ未選択）へ遷移する。  
   選択更新は既存 `activateItem`/`fireSelectionChanged` 契約を利用。
4. 選択・Contents同期の整合維持  
   [app/javascript/lib/selected_li_base_controller.js](app/javascript/lib/selected_li_base_controller.js) と [app/javascript/controllers/pane_focus_controller.js](app/javascript/controllers/pane_focus_controller.js) の既存イベント連携に合わせ、削除後に `changeSelectedLi` が確実に発火するようにする（右ペインの非表示/再表示キャッシュ同期を破壊しない）。
5. Trash画面の扱いを固定  
   [app/views/articles/trash.html.erb](app/views/articles/trash.html.erb)（同じリスト部分適用時）では、今回の改修で挙動変更しないことを明示し、次ステップで完全削除対応へ分離可能な構造にする。
6. テスト追加・更新  
   [spec/system/home_page_spec.rb](spec/system/home_page_spec.rb) もしくは近接specに以下を追加:  
   - 複数選択 + Backspace で全選択記事がゴミ箱化される  
   - 一部失敗時は成功分のみ消える  
   - 削除後フォーカスが次項目へ移る  
   - Contentsペインが残存選択に同期する

**Verification**
- System spec: 複数選択Backspaceの全件反映、best-effort、削除後フォーカス、contents同期を確認。
- 手動確認: `Cmd+Click`/`Shift+Click` で複数選択 → Backspace → 期待件数が記事一覧から消えること、右ペインが残存選択に追従することを確認。
- 退行確認: 単一選択時の Backspace、Space、上下移動、Enter が従来通り動くことを確認。

**Decisions**
- API方式: 既存 member `disable` を選択件数ぶん呼ぶ。
- 失敗時: 成功分のみ反映（best-effort）。
- 削除後フォーカス: 削除範囲の次項目を1件選択。
- Trash時Backspace: 今回は現状維持、次ステップで完全削除を検討。
