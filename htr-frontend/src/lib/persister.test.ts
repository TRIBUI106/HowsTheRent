import { describe, it, expect, vi } from 'vitest'
import { getPersister, removePersistedCache, CACHE_BUSTER } from './persister'

describe('getPersister', () => {
  it('returns a persister backed by localStorage', () => {
    const persister = getPersister()
    expect(persister).not.toBeNull()
    expect(typeof persister?.persistClient).toBe('function')
  })

  it('returns null and does not throw when localStorage.setItem throws', () => {
    const original = window.localStorage.setItem
    vi.spyOn(window.localStorage.__proto__, 'setItem').mockImplementation(() => {
      throw new Error('quota exceeded')
    })
    expect(() => getPersister()).not.toThrow()
    expect(getPersister()).toBeNull()
    window.localStorage.setItem = original
    vi.restoreAllMocks()
  })
})

describe('CACHE_BUSTER', () => {
  it('is a non-empty string', () => {
    expect(typeof CACHE_BUSTER).toBe('string')
    expect(CACHE_BUSTER.length).toBeGreaterThan(0)
  })
})

describe('removePersistedCache', () => {
  it('does not throw when called', () => {
    expect(() => removePersistedCache()).not.toThrow()
  })
})
