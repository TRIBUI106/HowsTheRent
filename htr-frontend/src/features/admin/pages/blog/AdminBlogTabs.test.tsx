import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import AdminBlogTabs from './AdminBlogTabs'

vi.mock('@/api', () => ({
  adminBlogApi: { listAll: vi.fn() },
}))

function renderAt(pathname: string) {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={[pathname]}>
        <Routes>
          <Route path="/admin/blog" element={<AdminBlogTabs />} />
          <Route path="/admin/blog/comments" element={<AdminBlogTabs />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('AdminBlogTabs', () => {
  beforeEach(() => {
    vi.mocked(adminBlogApi.listAll).mockResolvedValue([
      { postId: '1', roomId: 'r1', roomNumber: 'A101', propertyId: 'p1', propertyName: 'Nhà A', title: 'Bài A', slug: 'bai-a', published: true, likeCount: 5, updatedAt: null },
      { postId: '2', roomId: 'r1', roomNumber: 'A101', propertyId: 'p1', propertyName: 'Nhà A', title: 'Bài B', slug: 'bai-b', published: false, likeCount: 3, updatedAt: null },
    ])
  })

  it('renders both tabs linking to the post list and comment moderation views', () => {
    renderAt('/admin/blog')

    expect(screen.getByRole('link', { name: 'Bài viết' })).toHaveAttribute('href', '/admin/blog')
    expect(screen.getByRole('link', { name: 'Bình luận' })).toHaveAttribute('href', '/admin/blog/comments')
  })

  it('marks the "Bài viết" tab active on the list route, not on the comments route', () => {
    renderAt('/admin/blog')
    expect(screen.getByRole('link', { name: 'Bài viết' })).toHaveClass('text-accent')
    expect(screen.getByRole('link', { name: 'Bình luận' })).not.toHaveClass('text-accent')
  })

  it('marks the "Bình luận" tab active on the comments route', () => {
    renderAt('/admin/blog/comments')
    expect(screen.getByRole('link', { name: 'Bình luận' })).toHaveClass('text-accent')
    expect(screen.getByRole('link', { name: 'Bài viết' })).not.toHaveClass('text-accent')
  })

  it('shows the total like count summed across all posts', async () => {
    renderAt('/admin/blog')
    expect(await screen.findByText('Tổng lượt thích: 8')).toBeInTheDocument()
  })

  it('shows a total of 0 while posts are still loading or if there are none', () => {
    vi.mocked(adminBlogApi.listAll).mockReturnValue(new Promise(() => {}))
    renderAt('/admin/blog')
    expect(screen.getByText('Tổng lượt thích: 0')).toBeInTheDocument()
  })
})
