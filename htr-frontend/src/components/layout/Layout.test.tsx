import { describe, it, expect, beforeEach, vi } from 'vitest'
import { act, render, screen } from '@testing-library/react'

vi.mock('./Sidebar', () => ({
  default: () => <aside />,
}))
vi.mock('./Header', () => ({
  default: () => <header />,
}))
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import Layout from './Layout'

function renderLayout() {
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <BrowserRouter>
        <Layout title="Trang thử nghiệm">
          <div>Nội dung thử nghiệm</div>
        </Layout>
      </BrowserRouter>
    </QueryClientProvider>,
  )
}

describe('Layout offline spacing', () => {
  beforeEach(() => {
    Object.defineProperty(window.navigator, 'onLine', {
      value: true,
      configurable: true,
    })
  })

  it('reserves space for the fixed offline banner only while offline', () => {
    renderLayout()
    const layout = screen.getByTestId('app-layout')

    expect(layout).not.toHaveClass('pt-10')

    act(() => {
      window.dispatchEvent(new Event('offline'))
    })

    expect(layout).toHaveClass('pt-10')

    act(() => {
      window.dispatchEvent(new Event('online'))
    })

    expect(layout).not.toHaveClass('pt-10')
  })
})
