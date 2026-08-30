import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { blogApi } from '@/api'
import BlogListPage from './BlogListPage'

vi.mock('@/api', () => ({
  blogApi: { list: vi.fn() },
}))

function renderPage() {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter>
        <BlogListPage />
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('BlogListPage', () => {
  it('renders each published post with its vacancy badge', async () => {
    vi.mocked(blogApi.list).mockResolvedValue([
      {
        id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp Quận 1', coverImageUrl: null,
        propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi',
        emptyRoomCount: 2, totalRoomCount: 5, publishedAt: '2026-08-01T00:00:00',
      },
    ])

    renderPage()

    expect(await screen.findByText('Phòng trọ đẹp Quận 1')).toBeInTheDocument()
    expect(screen.getByText(/2 phòng trống/i)).toBeInTheDocument()
  })

  it('shows "Hết phòng" when there is no vacancy', async () => {
    vi.mocked(blogApi.list).mockResolvedValue([
      {
        id: '1', slug: 'phong-tro-day', title: 'Phòng trọ đầy', coverImageUrl: null,
        propertyId: 'p1', propertyName: 'Nhà trọ Đỏ', propertyAddress: '5 Trần Phú',
        emptyRoomCount: 0, totalRoomCount: 5, publishedAt: null,
      },
    ])

    renderPage()

    expect(await screen.findByText(/hết phòng/i)).toBeInTheDocument()
  })
})
