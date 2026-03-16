export function setPaneFocusEditLinkState(linkTarget, href) {
  if (href == null) {
    linkTarget.href = '#'
    linkTarget.dataset.disabled = true
    return
  }

  linkTarget.href = href
  linkTarget.dataset.disabled = false
}
