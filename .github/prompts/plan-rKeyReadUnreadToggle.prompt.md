## Plan: rキーで既読/未読トグル

`r` キー入力を記事リストのキーバインドに追加し、選択集合の unread 状態を評価して一括更新します。判定ルールは要望どおり、全未読なら全既読、全既読なら全未読、混在なら全未読です。既存の一括既読/未読処理（ボタンが使っている経路）を再利用するため、実装はフロント側のみで完結します。これにより API 追加なしで挙動を統一でき、保守性も維持できます。

**Steps**
1. `r` キーバインドを追加  
   [app/views/articles/_list.html.erb](app/views/articles/_list.html.erb) の `data-action` に `keydown.r->articles#toggleSelectedItemsReadStatus:prevent` を追加する。
2. トグル判定メソッドを追加  
   [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js) に `toggleSelectedItemsReadStatus` を追加し、`getSelectedItems()` の `data-unread` を集計する。
3. ルールに従って一括更新を呼び分け  
   同ファイルで既存 `markSelectedItemsRead` / `markSelectedItemsUnread` を呼び分ける。  
   - 全未読 → `markSelectedItemsRead()`  
   - 全既読 or 混在 → `markSelectedItemsUnread()`
4. no-op と失敗時方針を維持  
   選択ゼロ時は no-op（現仕様維持）、通信失敗は既存の best-effort/ログ方針をそのまま使う。
5. system spec を追加  
   新規 spec で `r` キー挙動を検証（全未読→既読、全既読→未読、混在→未読）。既存の一括ボタン spec は回帰確認として継続。
6. 回帰確認を実行  
   既存の複数選択・削除・contents 同期 spec を含めて system spec を実行し、キーバインド追加による副作用を確認する。

**Verification**
- 追加する `r` トグル spec が全ケースでパスすること。
- [spec/system/articles_bulk_read_unread_spec.rb](spec/system/articles_bulk_read_unread_spec.rb) 既存ケースが回帰しないこと。
- [spec/system/articles_bulk_delete_spec.rb](spec/system/articles_bulk_delete_spec.rb) と [spec/system/clear_contents_pane_spec.rb](spec/system/clear_contents_pane_spec.rb) が回帰しないこと。

**Decisions**
- 適用対象は記事リストのキー入力コンテキストのみ。
- 選択ゼロ時は no-op。
- 混在状態は全未読へ統一。
