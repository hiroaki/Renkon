## Plan: Mixed Tree Sortable Stabilization

グループと記事（subscription）を同一ソート面で扱うため、Sortableの管理対象を「全階層のUL」に統一し、`tree_nodes` を常に完全送信して `reorder_tree` で原子的に保存する。まずは判定を「ドロップ先リスト基準」に限定し、同列配置と子配置を確実に実現する。将来の横方向しきい値判定は拡張余地として分離する。

**Status Snapshot (2026-03-07)**
- 完了: nested sortable の主要挙動（group/subscription混在移動、子化、top-level復帰、リロード後の順序保持）は実装済み。
- 完了: `reorder_tree` 保存経路、`tree_nodes` 全量送信、root mixed描画（group/subscriptionをposition順で表示）。
- 完了: 公式 Nested Sortables Example に近い初期化（全ULへ Sortable 適用、`fallbackOnBody`/`swapThreshold`/`invertSwap`）。
- 未完了: 旧経路の整理（`PATCH /subscriptions/reorder` と `PATCH /groups/reorder` の退役方針確定・反映）。
- 未完了: DnD専用 system spec の新設（現在は既存 system/request で回帰確認）。
- 要判断: ルートグループの扱い（「固定かつ非表示」の方針に完全一致させるか、現状の表示運用を維持するか）。

**Open Questions (for next batch)**
1. 旧 `reorder` 系エンドポイントはこのタイミングで削除するか、互換のため1サイクル残すか。
2. ルートグループ（`Group.default_root!`）をUI非表示に寄せるか、現状どおり表示可能にするか。
3. DnD専用 system spec は今の区切りで追加するか、次の細かなUI調整と同じバッチで追加するか。

**Steps**
1. フェーズ1: 仕様固定（実装前合意）
2. 仕様を次で固定する: `subscription` は top-level 配置を許可、同一親で group/subscription を混在順序化、group へのドロップは子リストに入った場合のみ内包、ルートは「固定かつ非表示」の内部ノードとして扱う。*完了済み合意の文書化*
3. フェーズ2: フロントのSortable適用範囲を統一
4. `app/views/subscriptions/index.html.erb` の root UL と `app/views/subscriptions/_group_node.html.erb` の各ネスト UL へ同一の `subscriptions-tree-sort` を適用し、すべて同じ Sortable `group.name` で接続する。*depends on 2*
5. 旧 `subscriptions-sort` / `groups-sort` のDOM依存を除去し、混在ドラッグ対象を `li[data-item-type="group"], li[data-item-type="subscription"]` に一本化する。*depends on 4*
6. 空グループへのドロップが実挙動で失敗する場合にのみ、子ULの最小高さやプレースホルダ表示を追加する（まずは追加なしでSortable挙動を検証）。*parallel with 5*
7. フェーズ3: ツリーペイロード生成の正規化
8. `app/javascript/controllers/subscriptions_tree_sort_controller.js` で、DOM全体から `tree_nodes` を再構築するロジックを整理する。各ノードの `parent_group_id` は「所属ULの親group」で一意決定し、siblings内 `position` を1始まりで再採番する。*depends on 4-6*
9. top-level subscription は `parent_group_id: null` を許容して送信する。group も top-level は `parent_group_id: null` とする。*depends on 8*
10. フェーズ4: バックエンド契約の整合
11. `app/controllers/subscriptions_controller.rb` の `reorder_tree` を現仕様に合わせて再確認し、top-level subscription (`parent_group_id=nil`) を正常系として扱うことを明示する（必要ならバリデーション文言も調整）。*depends on 9*
12. 旧 `PATCH /subscriptions/reorder` / `PATCH /groups/reorder` の実利用を停止し、移行期間中は非推奨扱いにするか内部委譲にまとめ、経路競合を無くす。*depends on 11*
13. フェーズ5: 回帰テスト拡充
14. `spec/requests/subscriptions/reorder_spec.rb` に mixed順序・groupの親変更・top-level subscription移動・不正parent/cycle・重複position を追加/更新し、`reorder_tree` 契約を固定する。*depends on 11-12*
15. `spec/system/home_page_spec.rb` とは別に、DnD専用 system spec（新規）を追加して以下を検証する: groupをsubscription間へ移動、subscriptionをgroup内/外へ移動、空グループへの投入、階層維持。*depends on 6,8,11*
16. フェーズ6: 仕上げと運用
17. 不要化した旧 controller/attribute を削除して最小構成化し、メンテナンス対象を `subscriptions-tree-sort` + `reorder_tree` に統一する。*depends on 14-15*
18. 操作仕様を短い開発者向けメモに追記する（同列配置は同階層UL、内包は子ULへドロップ）。*depends on 17*

**Relevant files**
- `app/views/subscriptions/index.html.erb` - rootソート領域の定義、controller割当の統一。
- `app/views/subscriptions/_group_node.html.erb` - ネストULへの controller 付与、空グループドロップゾーン可視化。
- `app/views/subscriptions/_subscription_node.html.erb` - mixedノードとしての共通属性維持。
- `app/javascript/controllers/subscriptions_tree_sort_controller.js` - 全階層Sortable初期化、`tree_nodes` 正規化送信。
- `app/javascript/controllers/subscriptions_sort_controller.js` - 旧経路（削除/退役対象）。
- `app/javascript/controllers/groups_sort_controller.js` - 旧経路（削除/退役対象）。
- `app/controllers/subscriptions_controller.rb` - `reorder_tree` 契約、バリデーション、保存トランザクション。
- `app/controllers/groups_controller.rb` - `reorder` の退役判断対象。
- `config/routes.rb` - reorder ルート整理。
- `spec/requests/subscriptions/reorder_spec.rb` - mixed tree API契約テスト。
- `spec/system/home_page_spec.rb` - 既存回帰。
- `spec/system/*` - DnD新規spec追加先。

**Verification**
1. `bundle exec rspec spec/requests/subscriptions/reorder_spec.rb` で `reorder_tree` の正常系/異常系が通ること。
2. `bundle exec rspec spec/system`（DnD追加spec含む）で、group/subscription混在移動と入れ子操作が安定すること。
3. 手動確認: ルートで group を subscription の間へ配置できること、group配下へ subscription を移せること、subscription を top-level へ戻せること。
4. 手動確認: 空グループにもドロップ可能で、保存後リロードして順序と階層が保持されること。
5. ネットワーク確認: `PATCH /subscriptions/reorder_tree` の payload が全ノードを含み、422が発生しないこと。

**Decisions**
- 採用: まずは「ドロップ先リスト基準」で同列/子を判定する（横方向しきい値判定は後続）。
- 採用: top-level subscription を正式サポートする（`group_id=nil`）。
- 採用: ルートは内部固定ノードとして扱い、UIには通常グループとして表示しない方針。
- スコープ外: 初期段階での高度なヒットエリア最適化（水平オフセット自動判定、細かな慣性調整）。

**Further Considerations**
1. 段階導入案: 先に mixed並び替えのみを完成させ、次PRで「横方向しきい値判定」を追加する分割がリスク最小。
2. UI補助: 空グループのドロップ補助は「必要性が確認できた場合のみ」導入し、導入時はhover時のみ強調して視覚ノイズを抑える。
3. 互換性: 旧reorderエンドポイントをすぐ削除せず、短期間は内部委譲で互換運用する選択肢がある.
