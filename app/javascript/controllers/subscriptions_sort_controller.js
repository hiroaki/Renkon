import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { getCsrfToken } from "lib/schema"

export default class extends Controller {
  static values = {
    url: String,
    groupId: Number,
  }

  connect() {
    this.sortable = new Sortable(this.element, {
      animation: 150,
      group: {
        name: 'subscriptions-grouped',
        pull: true,
        put: true,
      },
      draggable: 'li[data-item-type="subscription"]',
      onEnd: () => this.persistGroupedOrders(),
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
      this.sortable = null
    }
  }

  async persistGroupedOrders() {
    if (!this.urlValue) {
      console.error('subscriptions-sort: urlValue is missing')
      return
    }

    const groupedOrders = Array.from(document.querySelectorAll('ul[data-controller~="subscriptions-sort"]'))
      .map((list) => {
        const groupId = Number(list.dataset.subscriptionsSortGroupIdValue)
        const orderedIds = Array.from(list.children)
          .filter((elem) => elem.matches('li[data-item-type="subscription"]'))
          .map((li) => Number(li.dataset.subscription))
          .filter((id) => Number.isInteger(id) && id > 0)

        return { group_id: groupId, ordered_ids: orderedIds }
      })
      .filter((entry) => Number.isInteger(entry.group_id) && entry.group_id > 0)

    const allOrderedIds = groupedOrders.flatMap((entry) => entry.ordered_ids)
    if (allOrderedIds.length === 0) {
      return
    }

    const response = await fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': getCsrfToken(),
      },
      body: JSON.stringify({
        grouped_orders: groupedOrders,
      }),
    })

    if (!response.ok) {
      console.error('subscriptions-sort: failed to persist order', response.status)
    }
  }
}
