import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, act } from '@testing-library/react'
import OfflineBanner from './OfflineBanner'

describe('OfflineBanner', () => {
  afterEach(() => {
    Object.defineProperty(window.navigator, 'onLine', {
      value: true,
      configurable: true,
    })
  })

  it('renders nothing while online', () => {
    render(<OfflineBanner />)
    expect(screen.queryByText(/không có kết nối mạng/i)).toBeNull()
  })

  it('shows the banner when offline', () => {
    render(<OfflineBanner />)
    act(() => {
      window.dispatchEvent(new Event('offline'))
    })
    expect(screen.getByText(/không có kết nối mạng/i)).toBeInTheDocument()
  })
})
