import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { getCsrfToken } from "lib/schema"

export default class extends Controller {
  static values = {
    url: String,
  }

  connect() {
    this.sortable = new Sortable(this.element, {
      animation: 150,
      group: {
        name: 'groups-nested',
        pull: true,
        put: true,
      },
      draggable: 'li[data-item-type="group"]',
      fallbackOnBody: true,
      swapThreshold: 0.65,
      onEnd: () => this.persistGroupHierarchy(),
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
      this.sortable = null
    }
  }

  async persistGroupHierarchy() {
    if (!this.urlValue) {
      console.error('groups-sort: urlValue is missing')
      return
    }

    const groupNodes = Array.from(document.querySelectorAll('li[data-item-type="group"][data-group-id]'))
      .map((groupLi) => {
        const id = Number(groupLi.dataset.groupId)
        const parentGroupLi = groupLi.parentElement.closest('li[data-item-type="group"][data-group-id]')
        const parentId = parentGroupLi ? Number(parentGroupLi.dataset.groupId) : null

        const siblings = Array.from(groupLi.parentElement.children)
          .filter((elem) => elem.matches('li[data-item-type="group"][data-group-id]'))
        const position = siblings.indexOf(groupLi) + 1

        return {
          id,
          parent_id: parentId,
          position,
        }
      })
      .filter((node) => Number.isInteger(node.id) && node.id > 0 && node.position > 0)

    if (groupNodes.length === 0) {
      return
    }

    const response = await fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': getCsrfToken(),
      },
      body: JSON.stringify({ group_nodes: groupNodes }),
    })

    if (!response.ok) {
      console.error('groups-sort: failed to persist hierarchy', response.status)
    }
  }
}
