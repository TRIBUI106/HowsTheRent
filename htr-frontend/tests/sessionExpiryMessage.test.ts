import { describe, expect, test } from 'bun:test'

import { consumeSessionExpiryReason, rememberSessionExpiryReason } from '../src/lib/sessionExpiryMessage'

class MemoryStorage {
  private values = new Map<string, string>()

  getItem(key: string) {
    return this.values.get(key) ?? null
  }

  setItem(key: string, value: string) {
    this.values.set(key, value)
  }

  removeItem(key: string) {
    this.values.delete(key)
  }
}

describe('session expiry redirect message', () => {
  test('stores and consumes the expiry reason once', () => {
    const storage = new MemoryStorage()

    rememberSessionExpiryReason('Phiên đăng nhập đã hết hạn.', storage)

    expect(consumeSessionExpiryReason(storage)).toBe('Phiên đăng nhập đã hết hạn.')
    expect(consumeSessionExpiryReason(storage)).toBeNull()
  })

  test('does not store an empty expiry reason', () => {
    const storage = new MemoryStorage()

    rememberSessionExpiryReason('   ', storage)

    expect(consumeSessionExpiryReason(storage)).toBeNull()
  })
})
