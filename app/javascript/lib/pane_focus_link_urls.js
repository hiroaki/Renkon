export function buildInsertContextHref(baseHref, selectedItem, origin) {
  if (!selectedItem || !selectedItem.dataset.itemType || selectedItem.dataset.itemType === 'trash') {
    return baseHref;
  }

  const url = new URL(baseHref, origin);

  if (selectedItem.dataset.itemType === 'subscription' && selectedItem.dataset.subscription) {
    url.searchParams.set('insert_context_type', 'subscription');
    url.searchParams.set('insert_context_id', selectedItem.dataset.subscription);
    return url.pathname + url.search;
  }

  if (selectedItem.dataset.itemType === 'group' && selectedItem.dataset.groupId) {
    url.searchParams.set('insert_context_type', 'group');
    url.searchParams.set('insert_context_id', selectedItem.dataset.groupId);
    return url.pathname + url.search;
  }

  return baseHref;
}
