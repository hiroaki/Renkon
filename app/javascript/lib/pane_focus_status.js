export function showPaneFocusStatusMessage(statusAreaTarget, statusTextTarget, statusIdleTarget, message) {
  statusTextTarget.textContent = message
  statusAreaTarget.classList.remove('hidden')
  statusAreaTarget.classList.add('flex')
  statusIdleTarget.classList.add('hidden')
}

export function clearPaneFocusStatusMessage(statusAreaTarget, statusTextTarget, statusIdleTarget) {
  statusTextTarget.textContent = ''
  statusAreaTarget.classList.remove('flex')
  statusAreaTarget.classList.add('hidden')
  statusIdleTarget.classList.remove('hidden')
}
