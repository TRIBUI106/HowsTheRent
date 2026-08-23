import { describe, it, expect } from 'vitest'
import { createAppQueryClient } from './queryClient'

describe('createAppQueryClient', () => {
  it('sets a 60s default staleTime for queries', () => {
    const client = createAppQueryClient()
    expect(client.getDefaultOptions().queries?.staleTime).toBe(1000 * 60)
  })

  it('disables retry for mutations', () => {
    const client = createAppQueryClient()
    expect(client.getDefaultOptions().mutations?.retry).toBe(false)
  })
})
