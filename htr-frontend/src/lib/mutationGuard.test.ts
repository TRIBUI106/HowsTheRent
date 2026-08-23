// src/lib/mutationGuard.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { guardMutate, guardMutateAsync } from './mutationGuard'
import { showToast } from './toast'

vi.mock('./toast', () => ({ showToast: vi.fn() }))

describe('guardMutate', () => {
  beforeEach(() => vi.mocked(showToast).mockClear())

  it('runs the callback when online', () => {
    const run = vi.fn()
    guardMutate(true, run)
    expect(run).toHaveBeenCalledOnce()
    expect(showToast).not.toHaveBeenCalled()
  })

  it('blocks and toasts when offline', () => {
    const run = vi.fn()
    guardMutate(false, run)
    expect(run).not.toHaveBeenCalled()
    expect(showToast).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'error' })
    )
  })
})

describe('guardMutateAsync', () => {
  beforeEach(() => vi.mocked(showToast).mockClear())

  it('resolves the callback result when online', async () => {
    const run = vi.fn().mockResolvedValue('ok')
    await expect(guardMutateAsync(true, run)).resolves.toBe('ok')
    expect(run).toHaveBeenCalledOnce()
  })

  it('rejects without calling the callback when offline', async () => {
    const run = vi.fn()
    await expect(guardMutateAsync(false, run)).rejects.toThrow()
    expect(run).not.toHaveBeenCalled()
    expect(showToast).toHaveBeenCalledOnce()
  })
})
