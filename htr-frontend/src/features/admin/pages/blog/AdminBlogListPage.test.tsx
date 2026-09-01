import type { ReactNode } from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import AdminBlogListPage from './AdminBlogListPage'

vi.mock('@/api', () => ({
  adminBlogApi: { listAll: vi.fn(), publish: vi.fn(), unpublish: vi.fn(), delete: vi.fn() },
}))

// Layout pulls in Sidebar/Header, which in turn pull in useNotifications' SSE
// EventSource connection — not polyfilled in this test environment, and
// irrelevant to what this test verifies. Shallow-mock it to a passthrough,
// matching the rest of the admin page suite (no other admin page test
// renders through the real Layout either).
vi.mock('@/components/Layout', () => ({
  default: ({ children }: { children: ReactNode }) => children,
}))

function renderPage() {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter><AdminBlogListPage /></MemoryRouter>
    </QueryClientProvider>
  )
}

describe('AdminBlogListPage', () => {
  beforeEach(() => {
    vi.mocked(adminBlogApi.delete).mockReset()
    vi.mocked(adminBlogApi.listAll).mockResolvedValue([
      { postId: '1', roomId: 'r1', roomNumber: 'A101', propertyId: 'p1', propertyName: 'Nhà A', title: 'Bài A', slug: 'bai-a', published: true, likeCount: 5, updatedAt: null },
      { postId: '2', roomId: 'r1', roomNumber: 'A101', propertyId: 'p1', propertyName: 'Nhà A', title: 'Bài B', slug: 'bai-b', published: false, likeCount: 0, updatedAt: null },
      { postId: '3', roomId: 'r1', roomNumber: 'A101', propertyId: 'p1', propertyName: 'Nhà A', title: 'Bài C', slug: 'bai-c', published: false, likeCount: 0, updatedAt: null, publishAt: '2026-12-01T10:00:00' },
    ])
  })

  it('shows every post, including multiple posts for one room', async () => {
    renderPage()

    expect(await screen.findByText('Bài A')).toBeInTheDocument()
    expect(screen.getByText('Bài B')).toBeInTheDocument()
    expect(screen.getAllByText('A101')).toHaveLength(3)
    expect(screen.getByText('Đã xuất bản')).toBeInTheDocument()
    expect(screen.getByText('Bản nháp')).toBeInTheDocument()
    expect(screen.getByText('5')).toBeInTheDocument()
  })

  it('shows a scheduled post as "Đã lên lịch" rather than a plain draft', async () => {
    renderPage()

    expect(await screen.findByText('Bài C')).toBeInTheDocument()
    expect(screen.getByText('Đã lên lịch')).toBeInTheDocument()
  })

  it('deletes a post only after confirmation', async () => {
    vi.mocked(adminBlogApi.delete).mockResolvedValue(undefined)
    renderPage()

    fireEvent.click(await screen.findAllByRole('button', { name: 'Xóa' }).then(buttons => buttons[0]))

    expect(adminBlogApi.delete).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Xóa bài viết' }))
    await waitFor(() => expect(adminBlogApi.delete).toHaveBeenCalledWith('1'))
  })
})
