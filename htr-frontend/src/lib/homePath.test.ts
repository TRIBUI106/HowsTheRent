import { describe, it, expect } from 'vitest'
import { homePathForRole } from './homePath'

describe('homePathForRole', () => {
  it('sends admin roles to /admin', () => {
    expect(homePathForRole('ADMIN')).toBe('/admin')
    expect(homePathForRole('PLATFORM_ADMIN')).toBe('/admin')
    expect(homePathForRole('LANDLORD_ADMIN')).toBe('/admin')
  })

  it('sends TENANT to /tenant', () => {
    expect(homePathForRole('TENANT')).toBe('/tenant')
  })

  it('sends GUEST to /blog', () => {
    expect(homePathForRole('GUEST')).toBe('/blog')
  })

  it('falls back to /tech for TECHNICIAN', () => {
    expect(homePathForRole('TECHNICIAN')).toBe('/tech')
  })
})
