/**
 * group_collapse_animation.js
 *
 * グループの折りたたみ／展開アニメーション。
 *
 * DOM 構造の前提:
 *   <div data-tree-sort-container>   ← container (クリッピング役; height をアニメーション)
 *     <ul data-tree-sort-list>       ← ul (コンテンツ役; translateY をアニメーション)
 *       ...
 *     </ul>
 *   </div>
 *
 * 視覚効果:
 *   - 閉じる: コンテンツ位置を保ったまま上へスライドアップしてクリップされる
 *   - 開く:   閉じるの完全逆再生（最下段から現れて元の位置へ落ちる）
 *
 * Public API:
 *   collapseGroup(container, { onDone })
 *   expandGroup(container, { onDone })
 *   cancelGroupAnimation(container)
 *   setGroupVisibilityInstant(container, hidden)
 */

const DURATION_MS = 160;
const EASING = 'ease-in-out';

// container 直下の ul を返す
function getUl(container) {
  return container.querySelector(':scope > ul[data-tree-sort-list]');
}

// アニメーション用インラインスタイルをすべてリセットする
function clearStyles(container) {
  const ul = getUl(container);
  container.style.transition = '';
  container.style.overflow = '';
  container.style.height = '';
  if (ul) {
    ul.style.transition = '';
    ul.style.transform = '';
  }
}

/**
 * 進行中のアニメーションを中断し、現在の中間状態で静止させる。
 * 続けて別方向のアニメーションを開始する前に呼ぶこと（連打対応）。
 */
function cancelInProgress(container) {
  if (!container._groupCollapseAnim) return;

  const { ul, fullHeight, rafId, timeoutId, onEnd } = container._groupCollapseAnim;
  const currentHeight = container.getBoundingClientRect().height;
  // height と translateY は常に「currentTranslateY = currentHeight - fullHeight」の関係を保つ
  const currentTranslateY = currentHeight - fullHeight;

  container.removeEventListener('transitionend', onEnd);
  window.clearTimeout(timeoutId);
  if (rafId) window.cancelAnimationFrame(rafId);
  container._groupCollapseAnim = null;

  // transition なしで現在位置に固定
  container.style.transition = 'none';
  container.style.overflow = 'hidden';
  container.style.height = `${currentHeight}px`;
  if (ul) {
    ul.style.transition = 'none';
    ul.style.transform = `translateY(${currentTranslateY}px)`;
  }
  container.offsetHeight; // リフロー確定
  container.style.transition = '';
  if (ul) ul.style.transition = '';
}

/**
 * container.height と ul.translateY を同時にアニメーションさせる共通エンジン。
 * applyTarget() で終端スタイルをセットし、transitionend で onFinish() を呼ぶ。
 */
function runTransition(container, ul, fullHeight, applyTarget, onFinish) {
  const cleanup = () => {
    if (!container._groupCollapseAnim) return;
    container.removeEventListener('transitionend', container._groupCollapseAnim.onEnd);
    window.clearTimeout(container._groupCollapseAnim.timeoutId);
    if (container._groupCollapseAnim.rafId) {
      window.cancelAnimationFrame(container._groupCollapseAnim.rafId);
    }
    container.style.transition = '';
    if (ul) ul.style.transition = '';
    container._groupCollapseAnim = null;
  };

  const onEnd = (event) => {
    // ul の transform transitionend などが気泡してきても無視する
    if (event.target !== container || event.propertyName !== 'height') return;
    cleanup();
    onFinish();
  };

  // transition を先にセット（初期フレームで遷移が始まらないよう RAF 内で target を適用）
  container.style.transition = `height ${DURATION_MS}ms ${EASING}`;
  if (ul) ul.style.transition = `transform ${DURATION_MS}ms ${EASING}`;

  container._groupCollapseAnim = {
    onEnd,
    ul,
    fullHeight,
    // transitionend が来ない最悪ケースへのフォールバック
    timeoutId: window.setTimeout(() => { cleanup(); onFinish(); }, DURATION_MS + 60),
    rafId: 0,
  };

  container.addEventListener('transitionend', onEnd);
  container._groupCollapseAnim.rafId = window.requestAnimationFrame(() => {
    applyTarget();
  });
}

// ─── Public API ───────────────────────────────────────────────────────────────

/**
 * グループを折りたたむ（上へスライドアップ）。
 * @param {HTMLElement} container  data-tree-sort-container の要素
 * @param {{ onDone?: () => void }} options
 */
export function collapseGroup(container, { onDone = () => {} } = {}) {
  cancelInProgress(container);
  container.hidden = false;
  const ul = getUl(container);

  const fullHeight = container.scrollHeight;
  if (fullHeight === 0) {
    container.hidden = true;
    clearStyles(container);
    onDone();
    return;
  }

  // 初期状態: container は完全展開・ul は自然な位置
  container.style.overflow = 'hidden';
  container.style.height = `${fullHeight}px`;
  if (ul) ul.style.transform = 'translateY(0px)';
  container.offsetHeight; // 初期状態をコミット

  runTransition(container, ul, fullHeight,
    () => {
      // 終端: container を 0 に縮め、ul を同量だけ上へ移動
      container.style.height = '0px';
      if (ul) ul.style.transform = `translateY(-${fullHeight}px)`;
    },
    () => {
      container.hidden = true;
      clearStyles(container);
      onDone();
    },
  );
}

/**
 * グループを展開する（下へスライドダウン）。折りたたみの完全逆再生。
 * @param {HTMLElement} container  data-tree-sort-container の要素
 * @param {{ onDone?: () => void }} options
 */
export function expandGroup(container, { onDone = () => {} } = {}) {
  cancelInProgress(container);
  container.hidden = false;
  const ul = getUl(container);

  // 一時的に height:0 で表示して scrollHeight（完全展開時の高さ）を計測する
  container.style.overflow = 'hidden';
  container.style.height = '0px';
  container.offsetHeight;
  const fullHeight = container.scrollHeight;
  if (fullHeight === 0) {
    clearStyles(container);
    onDone();
    return;
  }

  // 初期状態: collapseGroup の終端状態と完全一致させる（逆再生の起点）
  if (ul) ul.style.transform = `translateY(-${fullHeight}px)`;
  container.offsetHeight; // 初期状態をコミット

  runTransition(container, ul, fullHeight,
    () => {
      // 終端: collapseGroup の初期状態へ向けて戻す
      container.style.height = `${fullHeight}px`;
      if (ul) ul.style.transform = 'translateY(0px)';
    },
    () => {
      clearStyles(container);
      onDone();
    },
  );
}

/**
 * 進行中のアニメーションを中断して現在位置で静止させる。
 * @param {HTMLElement} container
 */
export function cancelGroupAnimation(container) {
  cancelInProgress(container);
}

/**
 * アニメーションなしで即座に表示／非表示を切り替える（初期状態の復元などに使用）。
 * @param {HTMLElement} container
 * @param {boolean} hidden
 */
export function setGroupVisibilityInstant(container, hidden) {
  cancelInProgress(container);
  container.hidden = hidden;
  clearStyles(container);
}
