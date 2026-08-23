import { describe, it, expect, vi, beforeEach } from 'vitest'
import { act, renderHook } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import type { ReactNode } from 'react'
import { useNotificationReadMutations } from './useNotificationReadMutations'
import { showToast } from '@/lib/toast'

const { markRead, markAllRead } = vi.hoisted(() => ({
  markRead: vi.fn(),
  markAllRead: vi.fn(),
}))

vi.mock('@/api', () => ({
  notificationApi: { markRead, markAllRead },
}))
vi.mock('@/lib/toast', () => ({ showToast: vi.fn() }))

function wrapper({ children }: { children: ReactNode }) {
  return <QueryClientProvider client={new QueryClient()}>{children}</QueryClientProvider>
}

describe('useNotificationReadMutations', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    Object.defineProperty(window.navigator, 'onLine', {
      value: false,
      configurable: true,
    })
  })

  it('blocks an offline mark-read before its request or optimistic update runs', () => {
    const { result } = renderHook(() => useNotificationReadMutations(), { wrapper })

    act(() => result.current.markOneMutation.mutate('notification-1'))

    expect(markRead).not.toHaveBeenCalled()
    expect(result.current.markOneMutation.isIdle).toBe(true)
    expect(showToast).toHaveBeenCalledOnce()
  })
})
