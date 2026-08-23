// src/lib/mutationGuard.ts
import { showToast } from './toast'

export const OFFLINE_WRITE_MESSAGE =
  'Không có kết nối mạng, thao tác này cần mạng để thực hiện.'

export function guardMutate(isOnline: boolean, run: () => void): void {
  if (!isOnline) {
    showToast({ message: OFFLINE_WRITE_MESSAGE, type: 'error' })
    return
  }
  run()
}

export function guardMutateAsync<T>(
  isOnline: boolean,
  run: () => Promise<T>
): Promise<T> {
  if (!isOnline) {
    showToast({ message: OFFLINE_WRITE_MESSAGE, type: 'error' })
    return Promise.reject(new Error('offline'))
  }
  return run()
}
