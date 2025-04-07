// コントローラ pane_focus_controller で捕捉するカスタムイベント

/* イベント - changeReadStatus
  既読ステータス (item.unread) を変更したときに発生させるイベント
  引数 li には発生元の <li> を与えてください。
  */
export function fireChangeReadStatusEvent(li) {
  const event = new CustomEvent('changeReadStatus', {
    detail: {},
    bubbles: true
  });

  li.dispatchEvent(event);
}

/* イベント - emptyTrash
  ゴミ箱を空にしたときに発生させるイベント
  引数 elem は pane-focus のスコープ内の任意の要素を渡してください。
  */
export function fireEmptyTrashEvent(elem) {
  const event = new CustomEvent('emptyTrash', {
    detail: {},
    bubbles: true
  });

  elem.dispatchEvent(event);
}

/* イベント - changeSelectedLiEvent
  */
export function fireChangeSelectedLiEvent(elem, newSelectedLi) {
  const event = new CustomEvent('changeSelectedLi', {
    detail: { selected: newSelectedLi },
    bubbles: true,
  });

  elem.dispatchEvent(event);
}

/*
  */
export function fireConnectedSelectedLiBaseController(controller) {
  // NOTE: メモリリークを懸念してインスタンスを渡していません、識別子（文字列）のみです
  const event = new CustomEvent('connectedSelectedLiBaseController', {
    detail: { identifier: controller.identifier },
    bubbles: true
  });
  controller.element.dispatchEvent(event);
}
