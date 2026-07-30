type ApiErrorPayload = {
  message?: unknown
}

type ApiErrorLike = {
  response?: { data?: ApiErrorPayload }
}

function isApiErrorLike(error: unknown): error is ApiErrorLike {
  return typeof error === 'object' && error !== null
}

export function getErrorMessage(error: unknown, fallback: string) {
  if (!isApiErrorLike(error)) return fallback

  const responseMessage = error.response?.data?.message
  if (typeof responseMessage === 'string' && responseMessage.trim()) {
    return responseMessage
  }

  return fallback
}
