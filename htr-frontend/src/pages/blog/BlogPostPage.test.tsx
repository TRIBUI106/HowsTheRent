import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import type { User } from '@/types'
import BlogPostPage from './BlogPostPage'

vi.mock('@/api', () => ({
  blogApi: {
    getBySlug: vi.fn(),
    getVacancy: vi.fn(),
    listComments: vi.fn(),
    addComment: vi.fn(),
    like: vi.fn(),
    unlike: vi.fn(),
  },
}))

function renderAtSlug(slug: string) {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={[`/blog/${slug}`]}>
        <Routes>
          <Route path="/blog/:slug" element={<BlogPostPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('BlogPostPage', () => {
  beforeEach(() => {
    useAuthStore.setState({ user: null })
    vi.mocked(blogApi.getBySlug).mockResolvedValue({
      id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp', content: '<p>Nội dung</p>', coverImageUrl: null,
      propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi', publishedAt: null, likeCount: 3,
    })
    vi.mocked(blogApi.getVacancy).mockResolvedValue({ emptyCount: 2, rentedCount: 3, totalCount: 5 })
    vi.mocked(blogApi.listComments).mockResolvedValue([])
  })

  it('renders post content and the live vacancy widget', async () => {
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText('Phòng trọ đẹp')).toBeInTheDocument()
    await waitFor(() => expect(screen.getByText(/2\/5 phòng còn trống/i)).toBeInTheDocument())
  })

  it('shows a login prompt instead of the comment form when logged out', async () => {
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText(/đăng nhập để bình luận/i)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /gửi bình luận/i })).not.toBeInTheDocument()
  })

  it('shows the comment form when logged in', async () => {
    // 'GUEST' matches the backend UserRole enum (Task 1) but the frontend
    // User.role union isn't widened to include it until Task 19 — cast
    // locally here rather than touching the shared type from this task.
    useAuthStore.setState({
      user: { id: 'u1', fullName: 'Khách A', email: 'a@example.com', role: 'GUEST', active: true } as unknown as User,
    })

    renderAtSlug('phong-tro-dep')

    expect(await screen.findByRole('button', { name: /gửi bình luận/i })).toBeInTheDocument()
  })
})
