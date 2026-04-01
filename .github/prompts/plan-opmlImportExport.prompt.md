## Plan: OPML Import/Export UI and Flow

購読ペイン最下部に固定 Settings 領域を追加し、popover メニューから Export/Import を起動します。
Export はオプション付きモーダルから OPML ダウンロード、Import はファイルアップロードで取り込みます。初期版は重複処理を簡素化し、後で拡張しやすい構造にします。

**Steps**
1. Phase 1: 購読ペイン下部に固定 Settings 領域を追加し、popover（Export / Import）を実装。
2. 既存の選択イベントを利用し、現在選択中（購読 or グループ）の情報を Export フォームへ渡す。
3. Phase 2: Export モーダルを追加（scope: all/selected、include_groups チェック）。
4. Export 実行アクションを追加し、対象購読の抽出ロジックを実装。
5. OPML 生成サービスを追加し、include_groups=true ならグループ階層を outline ネストで出力、false ならフラット出力。
6. Phase 3: Import モーダルを追加（.opml/.xml アップロード）。
7. Import 実行アクションを追加し、OPML 解析サービスで outline を走査して group/subscription 候補を抽出。
8. 永続化サービスで Group/Subscription を作成し、結果サマリ（created/skipped/invalid）を返却。
9. import 完了時に購読リスト再読み込み + modal close + 通知表示を既存 stream パターンで統一。
10. Phase 4: request/system spec を追加し、導線と主要分岐を検証。

**Relevant files**
- `app/views/subscriptions/main.html.erb` : 購読ペイン固定下部 UI の追加位置
- `app/views/subscriptions/index.html.erb` : リスト構造と選択状態の整合
- `app/javascript/controllers/subscriptions_controller.js` : 選択情報のハンドリング拡張
- `app/javascript/lib/selected_li_base_controller.js` : selectedItems イベント基盤
- `app/views/shared/_modal_frame.html.erb` : Export/Import モーダル再利用
- `app/javascript/controllers/modal_controller.js` : モーダル close 挙動再利用
- `app/controllers/subscriptions_controller.rb` : export/import アクション追加
- `app/controllers/concerns/subscriptions_streams.rb` : modal close + list refresh 再利用
- `config/routes.rb` : collection ルート追加
- `app/models/group.rb` : 階層グループ永続化
- `app/models/subscription.rb` : src 重複判定
- `app/services/subscriptions/reorder_tree_validation_service.rb` : services 命名/配置の参照
- `spec/requests/subscriptions/index_spec.rb` : request spec スタイル参照
- `spec/system/subscriptions_spec.rb` : modal/system spec スタイル参照

**Verification**
1. Request: Export（all/selected、include_groups true/false）で OPML が返る。
2. Request: selected=group で配下を再帰出力、selected=subscription で単体出力。
3. Request: Import 正常系で永続化、重複時の想定動作、不正 XML でエラー。
4. System: Settings 固定表示、popover 開閉（外側クリック/ESC）。
5. System: Export/Import モーダル導線と実行後の UI 更新。

## 不足情報（最小）
1. Import 重複時の初期動作を最終確定したいです。
現時点では「初期版は実装が簡単な方式」というご意向に合わせ、src 重複はスキップを推奨として計画化しています。ここを確定できれば実装に迷いなく入れます。
==>スキップでよいです
