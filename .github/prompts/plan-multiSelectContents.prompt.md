## Plan: 複数選択と複数本文表示

単一選択前提の選択・描画契約を、既存構造を保ったまま拡張します。期待挙動は「購読選択で記事リスト更新 → 記事の複数選択集合を管理 → 右ペインに選択記事ぶんをDOM順で表示」です。重要点は、右ペインのクリアは購読切替の直接操作ではなく、記事リスト差し替えで選択集合が空になった結果として同期的に消えることに統一します。初期版は選択時に全件読み込み、再選択キャッシュは後段追加しやすい差し込み点だけ先に作ります。

**Steps**
1. 表示契約の分離  
   [app/views/articles/show.html.erb](app/views/articles/show.html.erb) の単一 contents フレーム依存を分離し、本文本体のみを返す部分テンプレート経路を追加。通常の show 表示用途は維持。
2. 記事行メタ情報の整理  
   [app/views/articles/_list.html.erb](app/views/articles/_list.html.erb) に記事ID・本文取得URL・表示順キーを明示。単一 frame 宛先固定の依存を段階的に外す。
3. 複数選択ロジックの完成  
   [app/javascript/lib/selected_li_base_controller.js](app/javascript/lib/selected_li_base_controller.js) で single / Cmd+Click append / Shift+Click range を実装し、DOM順 selected 集合を返すAPIを追加。
4. 選択イベント契約の拡張  
   [app/javascript/lib/pane_focus_events.js](app/javascript/lib/pane_focus_events.js) の changeSelectedLi を、単一selectedではなく selectedItems と focusedItem を扱えるpayloadへ拡張。既存購読側利用箇所は互換維持。
5. Contents 複数描画同期  
   記事選択変更時に、右ペイン内の表示要素を選択集合と同期（追加・更新・削除）。対象は [app/javascript/controllers/articles_controller.js](app/javascript/controllers/articles_controller.js) もしくは専用 controller を追加して責務分離。
6. クリア条件の統一  
   [app/javascript/controllers/pane_focus_controller.js](app/javascript/controllers/pane_focus_controller.js) のクリア挙動を「選択集合が空になったら消す」に寄せる。購読切替は結果的に記事選択が消えることで contents が消える流れに統一。
7. スタイル整合  
   [app/assets/stylesheets/application.tailwind.css](app/assets/stylesheets/application.tailwind.css) の data-selected 前提スタイルが複数選択で破綻しないことを確認し、必要最小限調整。
8. 回帰・追加テスト  
   [spec/system/home_page_spec.rb](spec/system/home_page_spec.rb) と [spec/system/clear_contents_pane_spec.rb](spec/system/clear_contents_pane_spec.rb) を更新し、複数選択・複数本文表示・DOM順・購読切替時の間接クリアを検証。

**Definition of Done (Step別)**
- Step 1 完了条件: 本文描画を返す経路が `contents` 固定フレームに依存せず利用でき、既存 show ページ表示が壊れていない。
- Step 2 完了条件: 記事行から記事IDと本文取得URLを一意に取得でき、単一 frame 宛先前提の参照が残っていない。
- Step 3 完了条件: click/Cmd+click/Shift+click で単一・追加・範囲選択が再現し、`data-selected` がDOM上で正しく同期される。
- Step 4 完了条件: `changeSelectedLi` で selectedItems と focusedItem が受け渡しでき、購読側の既存ハンドラは退行しない。
- Step 5 完了条件: 選択集合の変更に応じて contents 側が追加・更新・削除され、表示順が記事リストDOM順になる。
- Step 6 完了条件: 購読切替時は記事リスト差し替えに伴う選択集合の空化を契機に contents が空になり、直接clear依存を持たない。
- Step 7 完了条件: 複数選択時のハイライトがフォーカスペイン/非フォーカスペイン双方で視認性を維持し、不要なスタイル変更がない。
- Step 8 完了条件: system spec と手動確認がすべて通過し、単一選択時の既存操作（上下移動/Enter/Space/削除）に回帰がない。

**Verification**
- System spec で以下を確認  
- 複数記事を選択すると右ペインに複数本文が表示される  
- 表示順は記事リストDOM順  
- 購読切替で記事リストが差し替わり、選択集合が空になって右ペインが消える  
- 単一選択時の既存操作（上下移動、Enter、Space、削除）が退行しない
- 手動確認  
- Cmd+Click と Shift+Click の選択挙動  
- 選択解除時の右ペイン同期  
- 連続選択時の読み込み取りこぼしなし

**Decisions**
- 右ペイン表示順: DOM順  
- 読み込みタイミング: 選択直後に全件  
- クリアの意味付け: 購読切替の直接クリアではなく、記事選択集合の変化に追従  
- 再選択キャッシュ: 初期版は毎回再取得、後段で差し込み可能な設計にする
