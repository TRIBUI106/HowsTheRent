type ToastType = 'info' | 'error'

type ToastPayload = {
  message: string
  type?: ToastType
  durationMs?: number
}

const TOAST_EVENT = 'htr:toast'

export function showToast(payload: ToastPayload) {
  window.dispatchEvent(new CustomEvent(TOAST_EVENT, { detail: payload }))
}

export function getToastEventName() {
  return TOAST_EVENT
}
