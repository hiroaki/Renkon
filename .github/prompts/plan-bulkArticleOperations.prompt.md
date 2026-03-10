## Plan: Bulk Article Operations

記事の既読/未読更新と削除（無効化/完全削除）を、記事単位の逐次リクエストから「一括API + 1回のUI反映」に移行します。
方針は `Best-effort`（成功分のみ反映、失敗分は返却）で、さらに単一操作も同じ一括API経路に統合します。

**Steps**
1. API契約を先に固定する
`article_ids`、更新対象（`target_unread`）、結果（成功ID/失敗ID/`errors`）のJSON仕様を定義。
2. ルーティング追加
`config/routes.rb` に記事コレクション向け一括エンドポイント（更新/削除）を追加。
3. `ArticlesController` に一括アクション実装
配列検証、ID正規化、購読スコープ検証、部分失敗の集約レスポンスを実装。
4. 削除の2段階仕様を維持
`disabled=false` は無効化、`disabled=true` は完全削除を一括で処理。
5. `articles_controller.js` を統合
複数選択だけでなく単体トグル/単体削除も内部的に一括API（`ids=[id]`）へ統一。
6. UI反映とイベントを集約
成功IDのみDOM反映し、購読バッヂ更新イベントは購読ID単位にまとめて発火。
7. テスト強化
request spec 新設（入力不正/混入ID/部分失敗）＋ system spec 更新（既読点、バッヂ、削除挙動、フォーカス遷移）。
8. 回帰確認と手動確認
大量選択時の体感改善、混在状態削除、失敗時の部分反映を検証。

**Relevant files**
- `config/routes.rb`
- `app/controllers/articles_controller.rb`
- `app/javascript/controllers/articles_controller.js`
- `app/views/articles/_list.html.erb`
- `spec/requests/`（新規一括API spec）
- `spec/system/articles_bulk_read_unread_spec.rb`
- `spec/system/articles_bulk_delete_spec.rb`
- `spec/system/articles_trash_backspace_destroy_spec.rb`

**Verification**
1. `bundle exec rspec spec/requests`（新設bulk request spec）
2. `bundle exec rspec spec/system/articles_bulk_read_unread_spec.rb spec/system/articles_bulk_delete_spec.rb spec/system/articles_trash_backspace_destroy_spec.rb`
3. 手動で10件以上選択し、Mark Read/Unread と Backspace の応答性・件数一致を確認

**Decisions**
- `Best-effort` を採用
- 単体操作も同一一括API経路へ統合
- 削除の2段階仕様（無効化→完全削除）は維持
