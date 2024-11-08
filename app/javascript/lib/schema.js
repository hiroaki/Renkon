function getMetaElement(name) {
  return document.querySelector(`meta[name="${name}"]`);
}

function getMetaContent(name) {
  const element = getMetaElement(name);
  return element && element.content;
}

function getCookieValue(cookieName) {
  if (cookieName != null) {
    const cookies = document.cookie ? document.cookie.split('; ') : []
    const cookie = cookies.find((cookie) => cookie.startsWith(cookieName))
    if (cookie) {
      const value = cookie.split('=').slice(1).join('=')
      return value ? decodeURIComponent(value) : undefined
    }
  }
}

export function getCsrfToken() {
  return getCookieValue(getMetaContent('csrf-param')) || getMetaContent('csrf-token')
}
