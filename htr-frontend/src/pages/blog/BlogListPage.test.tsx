import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
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
  it('renders each published post with its room-status badge', async () => {
    vi.mocked(blogApi.list).mockResolvedValue([
      {
        id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp Quận 1', coverImageUrl: null,
        roomId: 'r1', roomNumber: 'A101', roomStatus: 'EMPTY',
        propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi',
        publishedAt: '2026-08-01T00:00:00', tags: [],
      },
    ])

    renderPage()

    expect(await screen.findByText('Phòng trọ đẹp Quận 1')).toBeInTheDocument()
    expect(screen.getByText('Phòng A101 · Trống')).toBeInTheDocument()
  })

  it('shows the room status when a room is rented', async () => {
    vi.mocked(blogApi.list).mockResolvedValue([
      {
        id: '1', slug: 'phong-tro-day', title: 'Phòng trọ đầy', coverImageUrl: null,
        roomId: 'r1', roomNumber: 'B203', roomStatus: 'RENTED',
        propertyId: 'p1', propertyName: 'Nhà trọ Đỏ', propertyAddress: '5 Trần Phú',
        publishedAt: null, tags: [],
      },
    ])

    renderPage()

    expect(await screen.findByText('Phòng B203 · Đã thuê')).toBeInTheDocument()
  })

  it('shows each post\'s tags and filters the grid when a tag chip is clicked', async () => {
    vi.mocked(blogApi.list).mockResolvedValue([
      {
        id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp Quận 1', coverImageUrl: null,
        roomId: 'r1', roomNumber: 'A101', roomStatus: 'EMPTY',
        propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi',
        publishedAt: '2026-08-01T00:00:00', tags: ['gia-re'],
      },
      {
        id: '2', slug: 'phong-tro-day', title: 'Phòng trọ đầy', coverImageUrl: null,
        roomId: 'r2', roomNumber: 'B203', roomStatus: 'RENTED',
        propertyId: 'p1', propertyName: 'Nhà trọ Đỏ', propertyAddress: '5 Trần Phú',
        publishedAt: null, tags: ['trung-tam'],
      },
    ])

    renderPage()

    expect(await screen.findByText('Phòng trọ đẹp Quận 1')).toBeInTheDocument()
    expect(screen.getByText('Phòng trọ đầy')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'gia-re' }))

    expect(screen.getByText('Phòng trọ đẹp Quận 1')).toBeInTheDocument()
    expect(screen.queryByText('Phòng trọ đầy')).not.toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Tất cả' }))

    expect(screen.getByText('Phòng trọ đẹp Quận 1')).toBeInTheDocument()
    expect(screen.getByText('Phòng trọ đầy')).toBeInTheDocument()
  })
})
