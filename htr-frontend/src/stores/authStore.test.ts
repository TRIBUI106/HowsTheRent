import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useAuthStore } from './authStore'
import { removePersistedCache } from '@/lib/persister'

vi.mock('@/lib/persister', () => ({ removePersistedCache: vi.fn() }))

describe('authStore.clearAuth', () => {
  beforeEach(() => vi.mocked(removePersistedCache).mockClear())

  it('clears the persisted query cache on logout', () => {
    useAuthStore.getState().clearAuth()
    expect(removePersistedCache).toHaveBeenCalledOnce()
  })
})
