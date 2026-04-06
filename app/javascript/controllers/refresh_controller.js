import { Controller } from "@hotwired/stimulus"
import Queue from "promise-queue"
import RefreshDelegator from 'lib/refresh_delegator'
import { fireSubscriptionsRefreshedEvent } from 'lib/pane_focus_events'

export default class extends Controller {
  static values = { concurrency: Number }

  initialize() {
    this.concurrencyValue ||= 4;
    console.info(`refresh_controller#new: this.concurrencyValue=[${this.concurrencyValue}]`);
  }

  // refresh all subscriptions
  async all() {
    const generateFetchFunction = (li, urlRefresh, method, frame_id) => {
      return async () => {
        this.showLoading(li)

        try {
          const delegator = new RefreshDelegator(urlRefresh, method, frame_id)
          await delegator.perform()

          if (delegator.failed) {
            throw await delegator.getFailureDetails()
          }

          this.clearStatus(li)
        } catch (error) {
          console.error(`Failed to refresh frame ${frame_id}:`, error)
          this.showError(li, error)
        }
      }
    }

    const que = new Queue(this.concurrencyValue);
    const refreshTasks = []

    document.getElementById('subscriptions').querySelectorAll('li[data-item-type="subscription"]').forEach(li => {
      const urlRefresh = li.dataset['urlRefresh'];
      const turboFrame = li.querySelector('turbo-frame');

      // Skip nodes that are not refreshable subscriptions.
      if (!urlRefresh || !turboFrame) {
        return;
      }

      refreshTasks.push(que.add(
        generateFetchFunction(li, urlRefresh, 'PATCH', turboFrame.id)
      ))
    });

    await Promise.allSettled(refreshTasks)
    fireSubscriptionsRefreshedEvent(this.element)
  }

  findStatus(li) {
    return li.querySelector('[data-refresh-status]')
  }

  hiddenStatusClass() {
    return 'hidden h-5 min-w-5 items-center justify-center rounded-full px-1.5 font-semibold leading-none'
  }

  visibleStatusClass(colorClasses) {
    return `inline-flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 font-semibold leading-none ${colorClasses}`
  }

  showLoading(li) {
    const status = this.findStatus(li)
    if (!status) {
      return
    }

    status.className = this.visibleStatusClass('text-slate-700 bg-slate-100')
    status.setAttribute('aria-label', 'Refreshing subscription')
    status.removeAttribute('title')
    status.innerHTML = '<span class="inline-block h-3 w-3 animate-spin rounded-full border-2 border-slate-400 border-t-transparent" aria-hidden="true"></span>'
  }

  showError(li, error) {
    const status = this.findStatus(li)
    if (!status) {
      return
    }

    const category = error?.category === 'permanent' ? 'permanent' : 'temporary'
    const title = error?.message || (category === 'permanent'
      ? 'This source is not a valid RSS or Atom feed. Check the subscription URL or settings.'
      : 'The feed source is temporarily unavailable. Try again later.')

    status.className = this.visibleStatusClass(category === 'permanent' ? 'text-red-800 bg-red-100' : 'text-yellow-800 bg-yellow-100')
    status.setAttribute('aria-label', title)
    status.setAttribute('title', title)
    status.innerHTML = '<span aria-hidden="true">&#9888;</span>'
  }

  clearStatus(li) {
    const status = this.findStatus(li)
    if (!status) {
      return
    }

    status.className = this.hiddenStatusClass()
    status.innerHTML = ''
    status.removeAttribute('aria-label')
    status.removeAttribute('title')
  }
}
