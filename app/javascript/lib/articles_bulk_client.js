import { getCsrfToken } from 'lib/schema'

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

    const contentType = response.headers.get('content-type') || ''
    const data = contentType.includes('application/json') ? await response.json() : null

    if (!response.ok) {
      console.error('Bulk article operation failed', { url, status: response.status, data })
    }

    return { ok: response.ok, data }
  } catch (error) {
    console.error('Bulk article operation request error', { url, error })
    return { ok: false, data: null }
  }
}
