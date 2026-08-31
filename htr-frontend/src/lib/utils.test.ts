import { describe, it, expect } from 'vitest'
import { directionLabel, postStatusLabel } from './utils'

describe('directionLabel', () => {
  it('maps each of the 8 directions to a Vietnamese label', () => {
    expect(directionLabel('NORTH')).toBe('Bắc')
    expect(directionLabel('SOUTH')).toBe('Nam')
    expect(directionLabel('EAST')).toBe('Đông')
    expect(directionLabel('WEST')).toBe('Tây')
    expect(directionLabel('NORTHEAST')).toBe('Đông Bắc')
    expect(directionLabel('NORTHWEST')).toBe('Tây Bắc')
    expect(directionLabel('SOUTHEAST')).toBe('Đông Nam')
    expect(directionLabel('SOUTHWEST')).toBe('Tây Nam')
  })

  it('returns an em dash for null/undefined/empty', () => {
    expect(directionLabel(null)).toBe('—')
    expect(directionLabel(undefined)).toBe('—')
    expect(directionLabel('')).toBe('—')
  })

  it('falls back to the raw value for an unrecognized direction', () => {
    expect(directionLabel('UNKNOWN')).toBe('UNKNOWN')
  })
})

describe('postStatusLabel', () => {
  it('maps each status to a Vietnamese label', () => {
    expect(postStatusLabel('PUBLISHED')).toBe('Đã xuất bản')
    expect(postStatusLabel('DRAFT')).toBe('Bản nháp')
    expect(postStatusLabel('NONE')).toBe('Chưa có bài viết')
  })
})
