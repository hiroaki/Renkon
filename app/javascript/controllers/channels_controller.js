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
        li.remove();
      }
      else {
        console.error('Failed to delete the channel', response);
      }
    })
    .catch(error => console.error('Error:', error));
  }
}
