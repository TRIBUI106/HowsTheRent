// src/hooks/useGuardedMutation.test.tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, act, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import type { ReactNode } from 'react'
import { useGuardedMutation } from './useGuardedMutation'
import { showToast } from '@/lib/toast'

vi.mock('@/lib/toast', () => ({ showToast: vi.fn() }))

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient()
  return (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  )
}

describe('useGuardedMutation', () => {
  beforeEach(() => {
    vi.mocked(showToast).mockClear()
    Object.defineProperty(window.navigator, 'onLine', {
      value: true,
      configurable: true,
    })
  })

  it('calls through to mutationFn when online', async () => {
    const mutationFn = vi.fn().mockResolvedValue('ok')
    const { result } = renderHook(
      () => useGuardedMutation({ mutationFn }),
      { wrapper }
    )
    act(() => result.current.mutate(undefined))
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(mutationFn).toHaveBeenCalledOnce()
  })

  it('blocks mutate and toasts when offline', async () => {
    Object.defineProperty(window.navigator, 'onLine', {
      value: false,
      configurable: true,
    })
    const mutationFn = vi.fn().mockResolvedValue('ok')
    const { result } = renderHook(
      () => useGuardedMutation({ mutationFn }),
      { wrapper }
    )
    act(() => result.current.mutate(undefined))
    expect(mutationFn).not.toHaveBeenCalled()
    expect(showToast).toHaveBeenCalledOnce()
  })

  it('blocks mutateAsync and toasts when offline', async () => {
    Object.defineProperty(window.navigator, 'onLine', {
      value: false,
      configurable: true,
    })
    const mutationFn = vi.fn().mockResolvedValue('ok')
    const { result } = renderHook(
      () => useGuardedMutation({ mutationFn }),
      { wrapper }
    )
    await expect(result.current.mutateAsync(undefined)).rejects.toThrow()
    expect(mutationFn).not.toHaveBeenCalled()
    expect(showToast).toHaveBeenCalledOnce()
  })

  it('keeps mutate and mutateAsync referentially stable across re-renders when isOnline is unchanged', () => {
    const mutationFn = vi.fn().mockResolvedValue('ok')
    const { result, rerender } = renderHook(
      () => useGuardedMutation({ mutationFn }),
      { wrapper }
    )
    const firstMutate = result.current.mutate
    const firstMutateAsync = result.current.mutateAsync
    rerender()
    expect(result.current.mutate).toBe(firstMutate)
    expect(result.current.mutateAsync).toBe(firstMutateAsync)
  })
})
