## Plan: Shift+矢印で範囲選択拡張

対象は記事リスト（中央ペイン）のみとして、既存の Shift+クリック範囲選択ロジックを再利用し、Shift+↑/↓ でも macOS ネイティブに近い拡張/縮小を実現します。実装の中心は [app/javascript/lib/selected_li_base_controller.js](app/javascript/lib/selected_li_base_controller.js) で、既存の `selectItemRange` と `fireSelectionChanged` を活かすため変更範囲は小さく抑えられます。非Shift矢印時のアンカー更新も合わせて整えることで、次回の Shift+矢印の起点が自然になります。

**Steps**
1. キー処理分岐を追加  
   [app/javascript/lib/selected_li_base_controller.js](app/javascript/lib/selected_li_base_controller.js) の `selectPrevItem` / `selectNextItem` に `evt.shiftKey` 分岐を追加する。
2. Shift+矢印の範囲選択動作を実装  
   Shift 分岐では `selectItemRange(newLi)` → `moveFocusToItem(newLi)` → `fireSelectionChanged(newLi)` を行い、`activateItem` は使わない。
3. アンカー管理を明確化  
   非Shift矢印では従来どおり単一選択 (`activateItem`) にしたうえで、アンカーを新しい選択行へ更新する（次の Shift+矢印の起点を安定化）。
4. 既存ショートカットとの整合を確認  
   `r` / `u` / Backspace が `getSelectedItems()` ベースで範囲全体に作用することを維持する（変更対象: [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js) は原則無変更）。
5. system spec を追加  
   新規 spec で Shift+Down 拡張、Shift+Up 縮小、方向反転、非Shift矢印後の再起点を検証する。既存 spec へは最小追記に留める。
6. 回帰テスト実行  
   既存の複数選択・既読未読・削除・contents 同期の system spec を合わせて実行する。

**Verification**
- 新規 spec で以下を確認  
- Shift+Down で選択範囲が下方向に拡張  
- Shift+Up で選択範囲が縮小/逆方向拡張  
- 非Shift矢印後の Shift+矢印で起点が意図どおり更新  
- その範囲に対して `r` / `u` / Backspace が正しく作用
- 既存回帰  
- [spec/system/articles_bulk_read_unread_spec.rb](spec/system/articles_bulk_read_unread_spec.rb)  
- [spec/system/articles_bulk_delete_spec.rb](spec/system/articles_bulk_delete_spec.rb)  
- [spec/system/clear_contents_pane_spec.rb](spec/system/clear_contents_pane_spec.rb)

**Decisions**
- 対象スコープ: 記事リストのみ  
- 実装方針: 既存 `selectItemRange` 再利用  
- 互換方針: 既存の `r` / `u` / Backspace 動作を維持
