type ApiSessionExpiryInput = {
  status?: number
  retryAttempted: boolean
  sessionExpired: boolean
}

export function shouldExpireSessionFromApiError({
  status,
  retryAttempted,
  sessionExpired,
}: ApiSessionExpiryInput) {
  if (sessionExpired) return false
  return status === 401 && retryAttempted
}
