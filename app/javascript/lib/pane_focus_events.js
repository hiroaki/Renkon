// コントローラ pane_focus_controller で捕捉するカスタムイベント

export const PANE_FOCUS_EVENTS = {
  CHANGE_READ_STATUS: 'changeReadStatus',
  EMPTY_TRASH: 'emptyTrash',
  CHANGE_SELECTED_LI: 'changeSelectedLi',
  CONNECTED_SELECTED_LI_BASE_CONTROLLER: 'connectedSelectedLiBaseController',
  STATUS_ERROR: 'renkon:status-error',
  SUBSCRIPTIONS_REFRESHED: 'renkon:subscriptions-refreshed',
};

export function dispatchPaneFocusEvent(target, eventName, detail = {}) {
  const event = new CustomEvent(eventName, {
    detail,
    bubbles: true,
  });

  target.dispatchEvent(event);
}

/* イベント - changeReadStatus
  既読ステータス (item.unread) を変更したときに発生させるイベント
  引数 li には発生元の <li> を与えてください。
  */
export function fireChangeReadStatusEvent(li) {
  dispatchPaneFocusEvent(li, PANE_FOCUS_EVENTS.CHANGE_READ_STATUS);
}

/* イベント - emptyTrash
  ゴミ箱を空にしたときに発生させるイベント
  引数 elem は pane-focus のスコープ内の任意の要素を渡してください。
  */
export function fireEmptyTrashEvent(elem) {
  dispatchPaneFocusEvent(elem, PANE_FOCUS_EVENTS.EMPTY_TRASH);
}

/* イベント - changeSelectedLiEvent
  */
export function fireChangeSelectedLiEvent(elem, detail = {}) {
  dispatchPaneFocusEvent(elem, PANE_FOCUS_EVENTS.CHANGE_SELECTED_LI, detail);
}

/*
  */
export function fireConnectedSelectedLiBaseController(controller) {
  // NOTE: メモリリークを懸念してインスタンスを渡していません、識別子（文字列）のみです
  dispatchPaneFocusEvent(
    controller.element,
    PANE_FOCUS_EVENTS.CONNECTED_SELECTED_LI_BASE_CONTROLLER,
    { identifier: controller.identifier }
  );
}

export function fireStatusErrorEvent(target, message) {
  dispatchPaneFocusEvent(target, PANE_FOCUS_EVENTS.STATUS_ERROR, { message });
}

export function fireSubscriptionsRefreshedEvent(target, detail = {}) {
  dispatchPaneFocusEvent(target, PANE_FOCUS_EVENTS.SUBSCRIPTIONS_REFRESHED, detail);
}
