const SESSION_EXPIRY_REASON_KEY = 'htr:session-expiry-reason'

type SessionExpiryStorage = {
  getItem: (key: string) => string | null
  setItem: (key: string, value: string) => void
  removeItem: (key: string) => void
}

function getSessionStorage(): SessionExpiryStorage | null {
  if (typeof window === 'undefined') return null
  return window.sessionStorage
}

export function rememberSessionExpiryReason(
  reason: string | undefined,
  storage: SessionExpiryStorage | null = getSessionStorage(),
) {
  const trimmed = reason?.trim()
  if (!trimmed || !storage) return

  try {
    storage.setItem(SESSION_EXPIRY_REASON_KEY, trimmed)
  } catch {
    // Ignore storage failures so auth cleanup can still complete.
  }
}

export function consumeSessionExpiryReason(
  storage: SessionExpiryStorage | null = getSessionStorage(),
) {
  if (!storage) return null

  try {
    const reason = storage.getItem(SESSION_EXPIRY_REASON_KEY)
    storage.removeItem(SESSION_EXPIRY_REASON_KEY)
    return reason
  } catch {
    return null
  }
}
