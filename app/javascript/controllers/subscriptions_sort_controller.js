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
      draggable: 'li[data-item-type="subscription"]',
      onEnd: () => this.persistOrder(),
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
      this.sortable = null
    }
  }

  async persistOrder() {
    if (!this.urlValue) {
      console.error('subscriptions-sort: urlValue is missing')
      return
    }

    const orderedIds = Array.from(this.element.querySelectorAll('li[data-item-type="subscription"]'))
      .map((li) => Number(li.dataset.subscription))
      .filter((id) => Number.isInteger(id) && id > 0)

    if (orderedIds.length === 0) {
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
        ordered_ids: orderedIds,
        group_id: this.groupIdValue,
      }),
    })

    if (!response.ok) {
      console.error('subscriptions-sort: failed to persist order', response.status)
    }
  }
}
