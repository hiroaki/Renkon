import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['movablePane'];
  static values = {
    storageKey: String
  };

  connect() {
    console.info('frame_controller');
  }

  initialize() {
    console.log('initialize frame_controller');
    this.workaroundDisappearingDragImage();
    this.reset();
  }

  // 特定のペインのサイズ幅をコントロールできるように、ドラッグ可能な DIV を設けていますが、これをドラッグする際、
  // マウスの位置に追従して、もとの DIV の半透明になったものが表示されます（ドラッグイメージ）。
  // これは縦方向にも移動してしまうため、横方向だけに限定したいのですが、できなさそうでした。
  // 代替方法として、ドラッグイメージそのものを非表示にするために、ドラッグ Event の dataTransfer.setDragImage を用いて
  // ドラッグイメージを透明な画像に変更します。
  // ただし、実際の動作の観察の結果、この際セットする画像（ドラッグイメージ）は DOM に追加されている必要がありそうです。
  // さもないと favicon.ico が URL バーからビューポートのマウスの位置へ降りてくるような、妙な挙動を示します。
  // （ Chrome の場合。 Safari はエラーになり、実行が止まりました。）
  // これを避けるために HTML のほうで用のない画像を追加する作業をさせたくないため、見えない画像をここで作り、 DOM に追加します。
  // ただし、レイアウトに影響が出ないようにするにはサイズを 0px にしたいところですが、そうするとドラッグイメージが表示されず？
  // "妙な挙動" が再現してしまうため、それを避けるために style の値を工夫しています。
  workaroundDisappearingDragImage() {
    this.emptyImage = new Image();
    this.emptyImage.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==';

    const div = document.createElement('div');
    div.setAttribute('style', 'height: 0px; width: 1px; position: absolute; display: block; overflow: hidden');
    div.append(this.emptyImage);
    document.body.append(div);
  }

  storeWidth(storageKey, value) {
    if (storageKey) {
      localStorage.setItem(storageKey, value);
    }
  }

  restoreWidth(storageKey) {
    return localStorage.getItem(storageKey);
  }

  reset() {
    this.start_x = null;
    this.start_width = null;

    const width = this.restoreWidth(this.storageKeyValue);
    if (width) {
      this.movablePaneTarget.style.width = parseInt(width) + 'px';
    }
  }

  handlerDragStart(evt) {
    this.start_x = evt.x;
    this.start_width = this.movablePaneTarget.offsetWidth;
    evt.dataTransfer.setDragImage(this.emptyImage, 4, 4);
  }

  handlerDrag(evt) {
    // WORKAROUND:  drag を終了して dragend になる最後の drag イベントの evt.x が 0 になります（なぜ？バグ？）
    // このことから、 evt.x == 0 は無視します。
    // ちなみに dragend 時の evt.x は 0 ではなく、ちゃんとした位置になっています。
    if (evt.x != 0) {
      this.updateWidthOfTarget(evt.x - this.start_x);
    }
  }

  handlerDragover(evt) {
    evt.dataTransfer.dropEffect = 'move';
    evt.preventDefault();
  }

  handlerDragEnd(evt) {
    this.storeWidth(this.storageKeyValue, this.movablePaneTarget.offsetWidth);
    this.reset();
  }

  updateWidthOfTarget(delta_x) {
    const new_width = this.start_width + delta_x;
    // console.log("new_width="+ new_width, this)
    this.movablePaneTarget.style.width = parseInt(new_width) +'px'
  }
}