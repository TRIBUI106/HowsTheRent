import { describe, it, expect, afterEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useOnlineStatus } from './useOnlineStatus'

describe('useOnlineStatus', () => {
  afterEach(() => {
    Object.defineProperty(window.navigator, 'onLine', {
      value: true,
      configurable: true,
    })
  })

  it('starts as true when navigator.onLine is true', () => {
    const { result } = renderHook(() => useOnlineStatus())
    expect(result.current).toBe(true)
  })

  it('flips to false on the offline event', () => {
    const { result } = renderHook(() => useOnlineStatus())
    act(() => {
      window.dispatchEvent(new Event('offline'))
    })
    expect(result.current).toBe(false)
  })

  it('flips back to true on the online event', () => {
    const { result } = renderHook(() => useOnlineStatus())
    act(() => {
      window.dispatchEvent(new Event('offline'))
    })
    act(() => {
      window.dispatchEvent(new Event('online'))
    })
    expect(result.current).toBe(true)
  })
})
