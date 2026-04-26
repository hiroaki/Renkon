import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "backdrop", "exportLink"]
  static values = {
    exportUrl: String,
  }

  connect() {
    this.selectedItemType = null
    this.selectedItemId = null
    this.closeMenu()
    this.refreshExportUrl()
  }

  toggleMenu(event) {
    event.preventDefault()
    if (this.menuTarget.classList.contains("hidden")) {
      this.openMenu()
    } else {
      this.closeMenu()
    }
  }

  openMenu() {
    this.menuTarget.classList.remove("hidden")
    this.backdropTarget.classList.remove("hidden")
  }

  closeMenu(event) {
    this.menuTarget.classList.add("hidden")
    this.backdropTarget.classList.add("hidden")
  }

  onChangeSelectedLi(event) {
    const selected = event.detail?.selected
    if (!selected) {
      this.selectedItemType = null
      this.selectedItemId = null
      this.refreshExportUrl()
      return
    }

    const itemType = selected.dataset.itemType
    if (itemType === "subscription") {
      this.selectedItemType = "subscription"
      this.selectedItemId = selected.dataset.subscription || selected.dataset.subscriptionId || null
    } else if (itemType === "group") {
      this.selectedItemType = "group"
      this.selectedItemId = selected.dataset.groupId || selected.dataset.group || null
    } else {
      this.selectedItemType = null
      this.selectedItemId = null
    }

    this.refreshExportUrl()
  }

  refreshExportUrl() {
    const url = new URL(this.exportUrlValue, window.location.origin)

    if (this.selectedItemType && this.selectedItemId) {
      url.searchParams.set("selected_item_type", this.selectedItemType)
      url.searchParams.set("selected_item_id", this.selectedItemId)
    } else {
      url.searchParams.delete("selected_item_type")
      url.searchParams.delete("selected_item_id")
    }

    this.exportLinkTarget.href = url.toString()
  }
}
