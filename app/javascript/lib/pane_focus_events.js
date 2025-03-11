// コントローラ pane_focus_controller で捕捉するカスタムイベント

/* イベント - changeReadStatus
  既読ステータス (item.unread) を変更したときに発生させるイベント
  引数 li には発生元の <li> を与えてください。
  */
export function fireChangeReadStatusEvent(li) {
  const event = new CustomEvent('changeReadStatus', {
    detail: {},
    bubbles: true
  })

  li.dispatchEvent(event)
}

/* イベント - emptyTrash
  ゴミ箱を空にしたときに発生させるイベント
  引数 elem は pane-focus のスコープ内の任意の要素を渡してください。
  */
export function fireEmptyTrashEvent(elem) {
  const event = new CustomEvent('emptyTrash', {
    detail: {},
    bubbles: true
  })

  elem.dispatchEvent(event)
}

/* イベント - connectArticles
  articles-controller が connect されたときに発生させるイベント
  引数 elem はコントローラがセットされた要素を渡してください。
  */
export function fireConnectArticlesEvent(elem) {
  const event = new CustomEvent('connectArticles', {
    detail: {},
    bubbles: true
  })

  elem.dispatchEvent(event)
}
