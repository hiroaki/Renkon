import SelectedLiBaseController from 'lib/selected_li_base_controller'
import { getCsrfToken } from 'lib/schema'

export default class extends SelectedLiBaseController {
  // Channel の削除処理の前提として、この確認の動作を発動させるイベントに続いて、
  // 実際の destroy の処理へ進むイベントが、連続して仕込まれていることが期待されています。
  // その前提のもと、 confirm が No を返したときは、 destroy へ進むことをキャンセルするために
  // stopImmediatePropagation を呼び出すことにしています。
  confirmDestroy(evt) {
    const li = this.detectLiFrom(evt.target)
    const message = li.dataset.textForConfirmDestroy || 'Sure?';
    if (!confirm(message)) {
      evt.stopImmediatePropagation()
    }
  }

  // Channel の削除処理をリクエストします。
  destroyChannel(evt) {
    const li = this.detectLiFrom(evt.target)
    const url = li.dataset['urlDestroy'];

    return fetch(url, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': getCsrfToken() }
    })
    .then(response => {
      if (response.ok) {
        // 選択状態であった <li> を remove するので、選択状態がなくなった（変化した）ことを通知します。
        // イベントを dispatch する要素 li を先に remove してしまうと通知できなくなるため、
        // イベントを通知してから削除してます。
        // 他の（上層の）要素で dispatch して通知を送ればよいのですが、
        // どの要素が適切かの見極めができていないため、とりあえずの処置です。
        const event = new CustomEvent('changeSelectedLi', {
          detail: { selected: null },
          bubbles: true,
        });
        li.dispatchEvent(event);
        li.remove();
      }
      else {
        console.error('Failed to delete the channel', response);
      }
    })
    .catch(error => console.error('Error:', error));
  }
}
