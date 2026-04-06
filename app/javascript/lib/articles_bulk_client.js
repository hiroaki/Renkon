import { getCsrfToken } from 'lib/schema'

function parseRetryAfter(response) {
  const value = Number.parseInt(response.headers.get('Retry-After') || '', 10)
  return Number.isInteger(value) && value > 0 ? value : null
}

function buildBulkOperationErrorMessage(status, data, retryAfter) {
  // TODO: Fold this 429 branch into a shared error-response contract when request handling is unified app-wide.
  if (status === 429) {
    return retryAfter
      ? `You're doing that too quickly. Please wait ${retryAfter} seconds and try again.`
      : 'You\'re doing that too quickly. Please wait a moment and try again.'
  }

  if (typeof data?.message === 'string' && data.message.trim() !== '') {
    return data.message.trim()
  }

  return "Couldn't update the articles. Please try again."
}

async function parseResponseData(response) {
  const contentType = response.headers.get('content-type') || ''
  if (!contentType.includes('application/json')) {
    return null
  }

  try {
    return await response.json()
  } catch (_error) {
    return null
  }
}

export function groupItemsByUrl(items, urlDatasetKey) {
  return items.reduce((acc, item) => {
    const url = item.dataset[urlDatasetKey]
    if (!acc.has(url)) {
      acc.set(url, [])
    }

    acc.get(url).push(item)
    return acc
  }, new Map())
}

export function indexItemsByArticleId(items) {
  const entries = items
    .map((li) => [Number(li.dataset.articleId), li])
    .filter(([id]) => Number.isInteger(id) && id > 0)

  return new Map(entries)
}

export async function requestBulkOperation(url, payload) {
  try {
    const response = await fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': getCsrfToken(),
      },
      body: JSON.stringify(payload),
    })

    const data = await parseResponseData(response)
    const status = response.status
    const retryAfter = parseRetryAfter(response)

    if (!response.ok) {
      console.error('Bulk article operation failed', { url, status, data })
    }

    return {
      ok: response.ok,
      data,
      status,
      retryAfter,
      errorMessage: response.ok ? null : buildBulkOperationErrorMessage(status, data, retryAfter),
    }
  } catch (error) {
    console.error('Bulk article operation request error', { url, error })
    return {
      ok: false,
      data: null,
      status: null,
      retryAfter: null,
      errorMessage: "Couldn't update the articles. Please try again.",
    }
  }
}
