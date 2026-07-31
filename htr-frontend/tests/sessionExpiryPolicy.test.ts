import assert from 'node:assert/strict'
import test from 'node:test'

import { shouldExpireSessionFromApiError } from '../src/lib/sessionExpiryPolicy'

test('does not expire the session for transient gateway errors', () => {
  assert.equal(
    shouldExpireSessionFromApiError({
      status: 502,
      retryAttempted: false,
      sessionExpired: false,
    }),
    false,
  )
})

test('expires the session for a retried unauthorized response', () => {
  assert.equal(
    shouldExpireSessionFromApiError({
      status: 401,
      retryAttempted: true,
      sessionExpired: false,
    }),
    true,
  )
})

test('does not expire an already expired session again', () => {
  assert.equal(
    shouldExpireSessionFromApiError({
      status: 401,
      retryAttempted: true,
      sessionExpired: true,
    }),
    false,
  )
})
