import { describe, it, expect, afterEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useDocumentMeta } from './useDocumentMeta'

describe('useDocumentMeta', () => {
  afterEach(() => {
    document.title = ''
    document.querySelector('meta[name="description"]')?.remove()
  })

  it('sets document.title and the description meta tag', () => {
    renderHook(() => useDocumentMeta('Phòng trọ đẹp · HowsTheRent', 'Nhà trọ Xanh — 12 Lê Lợi'))

    expect(document.title).toBe('Phòng trọ đẹp · HowsTheRent')
    expect(document.querySelector('meta[name="description"]')?.getAttribute('content'))
      .toBe('Nhà trọ Xanh — 12 Lê Lợi')
  })

  it('reuses an existing meta tag instead of creating duplicates', () => {
    const { rerender } = renderHook(
      ({ title, description }) => useDocumentMeta(title, description),
      { initialProps: { title: 'A', description: 'first' } }
    )
    rerender({ title: 'B', description: 'second' })

    expect(document.querySelectorAll('meta[name="description"]')).toHaveLength(1)
    expect(document.querySelector('meta[name="description"]')?.getAttribute('content')).toBe('second')
  })
})
