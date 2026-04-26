import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async submit(event) {
    event.preventDefault()

    const form = event.currentTarget
    const submitButton = form.querySelector('input[type="submit"], button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = true
    }

    try {
      const response = await fetch(form.action, {
        method: form.method.toUpperCase(),
        body: new FormData(form),
        headers: {
          Accept: "application/xml, text/html",
          "X-Requested-With": "XMLHttpRequest",
        },
      })

      if (response.ok && response.headers.get("content-type")?.includes("application/xml")) {
        const blob = await response.blob()
        const fileName = this.extractFilename(response.headers.get("content-disposition")) || "subscriptions.opml"
        this.downloadBlob(blob, fileName)
        this.closeModal()
        return
      }

      await this.renderErrorModal(response)
    } catch (_error) {
      this.renderFallbackError("Export failed unexpectedly. Please try again.")
    } finally {
      if (submitButton) {
        submitButton.disabled = false
      }
    }
  }

  extractFilename(contentDisposition) {
    if (!contentDisposition) {
      return null
    }

    const utf8Match = contentDisposition.match(/filename\*=UTF-8''([^;]+)/i)
    if (utf8Match) {
      return decodeURIComponent(utf8Match[1])
    }

    const basicMatch = contentDisposition.match(/filename="?([^";]+)"?/i)
    return basicMatch ? basicMatch[1] : null
  }

  downloadBlob(blob, fileName) {
    const url = URL.createObjectURL(blob)
    const anchor = document.createElement("a")
    anchor.href = url
    anchor.download = fileName
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(url)
  }

  closeModal() {
    const modalFrame = document.querySelector("turbo-frame#modal")
    if (modalFrame) {
      modalFrame.innerHTML = ""
    }
  }

  async renderErrorModal(response) {
    const text = await response.text()
    const modalFrame = document.querySelector("turbo-frame#modal")
    if (!modalFrame) {
      return
    }

    const parsed = new DOMParser().parseFromString(text, "text/html")
    const nextModal = parsed.querySelector("turbo-frame#modal")
    if (nextModal) {
      modalFrame.replaceWith(nextModal)
      return
    }

    this.renderFallbackError("Export failed. Please check options and try again.")
  }

  renderFallbackError(message) {
    const modalFrame = document.querySelector("turbo-frame#modal")
    if (!modalFrame) {
      return
    }

    const alert = modalFrame.querySelector('[data-opml-export-target="alert"]')
    if (alert) {
      alert.textContent = message
      alert.classList.remove("hidden")
    }
  }
}
