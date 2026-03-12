import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    subscriptionId: Number,
    refreshUrl: String,
  }

  connect() {
    this.applied = false
    this.retryCount = 0
    this.maxRetryCount = 120
    this.boundHandleFrameLoad = this.handleFrameLoad.bind(this)

    const frame = this.subscriptionsFrame
    if (!frame) {
      return
    }

    frame.addEventListener('turbo:frame-load', this.boundHandleFrameLoad)

    // Run once in case the frame already finished loading before this controller connected.
    this.applyCreateFlow()
  }

  disconnect() {
    const frame = this.subscriptionsFrame
    if (!frame || !this.boundHandleFrameLoad) {
      return
    }

    frame.removeEventListener('turbo:frame-load', this.boundHandleFrameLoad)
  }

  handleFrameLoad() {
    this.applyCreateFlow()
  }

  async applyCreateFlow() {
    if (this.applied || !this.hasSubscriptionIdValue) {
      return
    }

    const subscriptionsController = this.findSubscriptionsController()
    if (!subscriptionsController) {
      this.retryApplyCreateFlow()
      return
    }

    const selected = subscriptionsController.selectBySubscriptionId(this.subscriptionIdValue)
    if (!selected) {
      this.retryApplyCreateFlow()
      return
    }

    this.applied = true

    const refreshed = await subscriptionsController.refreshItem(this.subscriptionIdValue, {
      dryRun: false,
      showStatusError: true,
      refreshUrl: this.hasRefreshUrlValue ? this.refreshUrlValue : null,
    })

    if (refreshed) {
      subscriptionsController.reloadArticlesPaneBySubscriptionId(this.subscriptionIdValue)
    }
  }

  retryApplyCreateFlow() {
    if (this.applied || this.retryCount >= this.maxRetryCount) {
      return
    }

    this.retryCount += 1

    window.requestAnimationFrame(() => this.applyCreateFlow())
  }

  findSubscriptionsController() {
    const frame = this.subscriptionsFrame
    if (!frame) {
      return null
    }

    const scope = frame.querySelector('[data-controller~="subscriptions"]')
    if (!scope) {
      return null
    }

    return scope.subscriptions || null
  }

  get subscriptionsFrame() {
    return document.querySelector('turbo-frame#subscriptions')
  }
}
