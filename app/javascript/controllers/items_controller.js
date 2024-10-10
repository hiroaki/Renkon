import SelectedLiBaseController from "lib/selected_li_base_controller"

export default class extends SelectedLiBaseController {
  selectUnreadItem(evt) {
    const items = document.getElementById('items').querySelectorAll('li');

    // items ペイン上からこのイベントが発生している場合は、
    // 現在の選択位置以降から未読を探すようにします（ channels ペインでは先頭から）
    let pos = -1;
    for (let i = 0; i < items.length; ++i) {
      if (items[i] == evt.currentTarget) {
        pos = i;
        break;
      }
    }

    for (let i = pos + 1; i < items.length; ++i) {
      if (items[i].dataset['unread'] == 'true') {
        this.enterItem(items[i]);
        break;
      }
    }
  }
}
