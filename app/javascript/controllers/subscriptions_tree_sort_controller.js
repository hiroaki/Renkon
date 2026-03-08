import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { getCsrfToken } from "lib/schema"

let persistInFlight = false
let persistQueued = false

export default class extends Controller {
  static values = {
    url: String,
  }

  connect() {
    this.sortables = this.sortableLists().map((list) => {
      return new Sortable(list, {
        group: 'subscriptions-tree',
        animation: 150,
        fallbackOnBody: true,
        swapThreshold: 0.65,
        invertSwap: true,
        dragoverBubble: true,
        draggable: 'li[data-item-type="subscription"], li[data-item-type="group"]',
        filter: '.group-collapse-toggle',
        preventOnFilter: false,
        onEnd: () => this.queuePersistTreeOrder(),
      })
    })
  }

  disconnect() {
    this.sortables?.forEach((sortable) => sortable.destroy())
    this.sortables = []
  }

  sortableLists() {
    return [this.element, ...this.element.querySelectorAll('ul[data-tree-sort-list]')]
  }

  queuePersistTreeOrder() {
    persistQueued = true
    if (persistInFlight) {
      return
    }

    this.persistTreeOrder()
  }

  async persistTreeOrder() {
    if (!this.urlValue) {
      console.error('subscriptions-tree-sort: urlValue is missing')
      return
    }

    if (persistInFlight) {
      persistQueued = true
      return
    }

    persistInFlight = true
    persistQueued = false

    const scope = this.element.closest('turbo-frame#subscriptions') || this.element.closest('body') || document

    const treeNodes = Array.from(scope.querySelectorAll('li[data-item-type="group"], li[data-item-type="subscription"]'))
      .map((node) => {
        const itemType = node.dataset.itemType
        const id = itemType === 'group' ? Number(node.dataset.groupId) : Number(node.dataset.subscription)

        const parentGroupLi = node.parentElement.closest('li[data-item-type="group"][data-group-id]')
        const parentGroupId = parentGroupLi ? Number(parentGroupLi.dataset.groupId) : null

        const siblings = Array.from(node.parentElement.children)
          .filter((elem) => elem.matches('li[data-item-type="group"], li[data-item-type="subscription"]'))

        return {
          item_type: itemType,
          id,
          parent_group_id: parentGroupId,
          position: siblings.indexOf(node) + 1,
        }
      })
      .filter((entry) => Number.isInteger(entry.id) && entry.id > 0 && entry.position > 0)

    if (treeNodes.length === 0) {
      persistInFlight = false
      return
    }

    try {
      const response = await fetch(this.urlValue, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': getCsrfToken(),
        },
        body: JSON.stringify({ tree_nodes: treeNodes }),
      })

      if (!response.ok) {
        const body = await response.text()
        console.error('subscriptions-tree-sort: failed to persist order', response.status, body)
        this.notifyPersistError()
      }
    } catch (error) {
      console.error('subscriptions-tree-sort: request error while persisting order', error)
      this.notifyPersistError()
    } finally {
      persistInFlight = false
      if (persistQueued) {
        this.persistTreeOrder()
      }
    }
  }

  notifyPersistError() {
    window.dispatchEvent(new CustomEvent('renkon:status-error', {
      detail: {
        message: "Couldn't save the new order. Please try again.",
      },
    }))
  }
}
