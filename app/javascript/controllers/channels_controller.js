import SelectedLiBaseController from "lib/selected_li_base_controller"

export default class extends SelectedLiBaseController {
  // RIGHT key from selected LI tag
  selectItem(evt) {
    console.log("-- selectItem()")
    const li = document.getElementById('items').querySelectorAll('li').item(0);
    if (li) {
      this.enterItem(li);
    }
  }

  // SPACE key from selected LI tag
  selectUnreadItem(evt) {
    console.log("-- selectUnreadItem()")
    const items = document.getElementById('items').querySelectorAll('li');
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
