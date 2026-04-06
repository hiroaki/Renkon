**Plan: Footer Status for Throttled Article Updates**

推奨は 2 段階です。まずは main 画面の記事更新系だけを対象に、既存 footer status を使って 429 や通信失敗を見える化します。その後、必要なら全更新系へ横展開します。

**Steps**
1. 最小改修の主軸として、[app/javascript/lib/articles_bulk_client.js](app/javascript/lib/articles_bulk_client.js#L23) で `response.ok` だけでなく `status`、JSON の `message`、`Retry-After` を解釈し、失敗理由を返せるようにする。
2. [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js#L100) と [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js#L232) で、未読/既読更新と bulk delete の失敗時に `fireStatusErrorEvent(window, message)` を発火し、成功時のみ DOM を更新する現状方針を維持する。
3. 429 専用文言を用意する。[config/initializers/rack_attack.rb](config/initializers/rack_attack.rb#L46) の `Retry-After` を使い、「少し待ってから再試行してください」を含むメッセージに寄せる。Rack::Attack 自体の閾値や responder は初手では変えない。
4. footer の見た目を少しだけ整える。[app/views/subscriptions/main.html.erb](app/views/subscriptions/main.html.erb#L238) の既存 `!` を赤い三角びっくりマーク相当へ差し替える。構造はそのままでよく、大きな UI 改修は不要。
5. system spec を追加する。[spec/system/articles_bulk_read_unread_spec.rb](spec/system/articles_bulk_read_unread_spec.rb) と [spec/system/articles_bulk_delete_spec.rb](spec/system/articles_bulk_delete_spec.rb) に、失敗時に footer status が出ること、記事 DOM が誤更新されないことを追加する。既存の [spec/system/footer_status_spec.rb](spec/system/footer_status_spec.rb) を流用する。
6. 本格改修を進める場合のみ、[app/javascript/controllers/trash_controller.js](app/javascript/controllers/trash_controller.js) や [app/javascript/controllers/opml_export_controller.js](app/javascript/controllers/opml_export_controller.js) まで含めた共通 request helper 化と、Turbo/Form 送信の失敗集約を別フェーズで設計する。

**Relevant files**
- [app/javascript/lib/articles_bulk_client.js](app/javascript/lib/articles_bulk_client.js)
- [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js)
- [app/javascript/lib/pane_focus_events.js](app/javascript/lib/pane_focus_events.js)
- [app/javascript/controllers/pane_focus_controller.js](app/javascript/controllers/pane_focus_controller.js)
- [app/javascript/lib/pane_focus_status.js](app/javascript/lib/pane_focus_status.js)
- [app/views/subscriptions/main.html.erb](app/views/subscriptions/main.html.erb)
- [config/initializers/rack_attack.rb](config/initializers/rack_attack.rb)
- [spec/system/footer_status_spec.rb](spec/system/footer_status_spec.rb)
- [spec/system/articles_bulk_read_unread_spec.rb](spec/system/articles_bulk_read_unread_spec.rb)
- [spec/system/articles_bulk_delete_spec.rb](spec/system/articles_bulk_delete_spec.rb)

**Verification**
1. 記事の未読/既読操作を成功させ、従来どおり DOM 更新されることを確認する。
2. 429 相当を発生させ、footer に赤い警告表示と文言が出ることを確認する。
3. bulk delete 失敗時に記事が消えず、footer にだけエラーが出ることを確認する。
4. 既存の購読ツリー保存失敗時 status 表示と競合しないことを確認する。

**規模感**
- 最小改修: 4 から 6 ファイル程度の変更、spec 2 から 3 本追加。既存導線の再利用が中心で、小さめのイテレーションで進めやすいです。
- 本格改修: 8 から 12 ファイル以上に広がる可能性が高く、Rails 側のレスポンス統一と複数 controller/Turbo hook の整理が必要です。これは別イテレーションとして切り出すのが妥当です.
