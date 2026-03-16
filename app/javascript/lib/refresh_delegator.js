import TurboFrameDelegator from 'lib/turbo_frame_delegator'
import { getCsrfToken } from 'lib/schema'

export default class RefreshDelegator extends TurboFrameDelegator {
  constructor(...args) {
    super(...args)
    this.failed = false
    this.failureReason = null
    this.failureDetailsPromise = null
  }

  // override
  prepareRequest(request) {
    super.prepareRequest(request)

    if (!request.isSafe) {
      const token = getCsrfToken()
      if (token) {
        request.headers['X-CSRF-Token'] = token
      }
    }
  }

  // override
  requestFailedWithResponse(request, response) {
    super.requestFailedWithResponse(request, response)
    this.failed = true
    this.failureReason = new Error(`Request failed with status ${response?.statusCode ?? 'unknown'}`)
    this.failureDetailsPromise = this.extractFailureDetails(response)
  }

  // override
  requestErrored(request, error) {
    super.requestErrored(request, error)
    this.failed = true
    this.failureReason = error instanceof Error ? error : new Error(String(error))
    this.failureDetailsPromise = Promise.resolve({
      category: 'temporary',
      message: 'Could not reach the feed source. Try again later.',
    })
  }

  async getFailureDetails() {
    if (!this.failureDetailsPromise) {
      return {
        category: 'temporary',
        message: 'Could not refresh this subscription. Try again later.',
      }
    }

    return this.failureDetailsPromise
  }

  async extractFailureDetails(response) {
    const fallbackCategory = response?.clientError ? 'permanent' : 'temporary'
    const fallbackMessage = fallbackCategory === 'permanent'
      ? 'This source is not a valid RSS or Atom feed. Check the subscription URL or settings.'
      : 'The feed source is temporarily unavailable. Try again later.'

    const contentType = response?.contentType || ''

    if (!contentType.includes('application/json')) {
      return { category: fallbackCategory, message: fallbackMessage }
    }

    try {
      const body = await response.responseText
      const data = JSON.parse(body)

      return {
        category: data?.category || fallbackCategory,
        message: data?.error || fallbackMessage,
      }
    } catch (_error) {
      return { category: fallbackCategory, message: fallbackMessage }
    }
  }
}
