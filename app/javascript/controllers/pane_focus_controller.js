import { Controller } from "@hotwired/stimulus";
import TurboFrameDelegator from "lib/turbo_frame_delegator"
import { getCsrfToken } from 'lib/schema'

class RefreshChannelDelegator extends TurboFrameDelegator {
  // override
  prepareRequest(request) {
    super.prepareRequest(request)
    console.log('request', request)

    if (!request.isSafe) {
      const token = getCsrfToken()
      if (token) {
        request.headers['X-CSRF-Token'] = token
      }
    }
  }
}

export default class extends Controller {
  static targets = ['channelsPane', 'itemsPane', 'contentsPane'];

  connect() {
    this.allPaneTargets().forEach((pane) => {
      pane.addEventListener('click', () => this.focusPane(pane));
    });
  }

  allPaneTargets() {
    return [this.channelsPaneTarget, this.itemsPaneTarget, this.contentsPaneTarget]
  }

  focusPane(pane) {
    this.allPaneTargets().forEach((pane) => pane.classList.remove('focused'));
    pane.classList.add('focused');
  }

  // keyup LEFT on items pane
  backToChannelPane(evt) {
    this.focusPane(this.channelsPaneTarget);

    const selectedChannel = this.channelsPaneTarget.querySelector('li[data-selected="true"]');
    selectedChannel.focus();
  }

  // keyup RIGHT on channels pane
  forwardToItemPane(evt) {
    this.focusPane(this.itemsPaneTarget);

    const selectedItems = this.itemsPaneTarget.querySelectorAll('li[data-selected="true"]');
    if (0 < selectedItems.length) {
      selectedItems.item(selectedItems.length - 1).focus();
    }
    else {
      const li = this.itemsPaneTarget.querySelectorAll('li').item(0);
      if (li) {
        li.closest('ul').items.enterItem(li);
      }
    }
  }

  // keyup SPACE on channels pane
  forwardToUnreadItemPane(evt) {
    this.focusPane(this.itemsPaneTarget);

    const items = this.itemsPaneTarget.querySelectorAll('li');
    let pos = -1;
    for (let i = 0; i < items.length; ++i) {
      if (items[i] == evt.currentTarget) {
        pos = i;
        break;
      }
    }

    for (let i = pos + 1; i < items.length; ++i) {
      let li = items[i];
      if (li.dataset['unread'] == 'true') {
        // call a method of items controller (based selected-li controller)
        li.closest('ul').items.enterItem(li);
        break;
      }
    }
  }

  selectPrevItem(evt) {
    const pane = evt.currentTarget;

    const selection = pane.querySelectorAll('li[data-selected="true"]');
    if (0 < selection.length) {
      pane.getElementsByTagName('ul').item(0).selectedLi.selectPrevLi(selection.item(0));
    }
    else {
      const li = pane.querySelectorAll('li')
      if (0 < li.length) {
        pane.getElementsByTagName('ul').item(0).selectedLi.enterItem(li.item(li.length - 1));
      }
    }
  }

  selectNextItem(evt) {
    const pane = evt.currentTarget;

    const selection = pane.querySelectorAll('li[data-selected="true"]');
    if (0 < selection.length) {
      pane.getElementsByTagName('ul').item(0).selectedLi.selectNextLi(selection.item(selection.length - 1));
    }
    else {
      const li = pane.querySelectorAll('li')
      if (0 < li.length) {
        pane.getElementsByTagName('ul').item(0).selectedLi.enterItem(li.item(0));
      }
    }
  }

  onChangeReadStatus(evt) {
    const channelId = evt.target.dataset['channel'];
    const li = this.channelsPaneTarget.querySelector('li[data-channel="'+ channelId +'"]');
    const turboFrame = li.querySelector('turbo-frame');
    if (turboFrame) {
      new RefreshChannelDelegator(
        li.dataset['urlRefresh'], 'PATCH', turboFrame.id, new URLSearchParams({short: true, dry_run: true})
      )
      .perform();
    }
  }

  onConnectItems(evt) {
    this.clearContentsPane();
  }

  onEmptyTrash(evt) {
    const selectedChannel = this.channelsPaneTarget.querySelector('li[data-selected="true"]');
    if (selectedChannel && selectedChannel.id == 'trash') {
      this.clearContentsPane();
      this.clearItemsPane();
    }
  }

  clearItemsPane() {
    this.itemsPaneTarget.querySelector('turbo-frame#items').innerHTML = '';
  }

  clearContentsPane() {
    this.contentsPaneTarget.querySelector('turbo-frame#contents').innerHTML = '';
  }
}
