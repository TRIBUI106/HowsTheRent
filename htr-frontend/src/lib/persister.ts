import { createSyncStoragePersister } from '@tanstack/query-sync-storage-persister'
import type { Persister } from '@tanstack/react-query-persist-client'

// Vite injects a fresh build id for production deployments and a stable id in dev.
export const CACHE_BUSTER = __HTR_BUILD_ID__
const STORAGE_KEY = 'htr-query-cache'

export function getPersister(): Persister | null {
  try {
    // createSyncStoragePersister() doesn't touch storage until persistClient()
    // is called, so probe with a real write here to detect an unavailable or
    // full localStorage up front.
    const probeKey = '__htr_storage_probe__'
    window.localStorage.setItem(probeKey, '1')
    window.localStorage.removeItem(probeKey)

    return createSyncStoragePersister({
      storage: window.localStorage,
      key: STORAGE_KEY,
    })
  } catch (error) {
    console.warn('React Query persistence disabled (localStorage unavailable):', error)
    return null
  }
}

export function removePersistedCache(): void {
  try {
    window.localStorage.removeItem(STORAGE_KEY)
  } catch (error) {
    console.warn('Failed to clear persisted query cache:', error)
  }
}
