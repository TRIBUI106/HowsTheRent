import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import BlogPostPage from './BlogPostPage'

vi.mock('@/api', () => ({
  blogApi: {
    list: vi.fn(),
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

const post = {
  id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp', content: '<p>Nội dung</p>', coverImageUrl: null,
  roomId: 'r1', roomNumber: 'A101', roomStatus: 'EMPTY' as const, roomDirection: 'NORTH' as const,
  roomAreaM2: 24, roomMaxPeople: 2, roomImages: ['https://example.test/room-a101.jpg'],
  propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi', publishedAt: null,
  likeCount: 3, liked: false,
}

describe('BlogPostPage', () => {
  beforeEach(() => {
    vi.mocked(blogApi.like).mockClear()
    vi.mocked(blogApi.unlike).mockClear()
    useAuthStore.setState({ user: null })
    vi.mocked(blogApi.getBySlug).mockResolvedValue(post)
    vi.mocked(blogApi.getVacancy).mockResolvedValue({ emptyCount: 2, rentedCount: 3, totalCount: 5 })
    vi.mocked(blogApi.listComments).mockResolvedValue([])
    vi.mocked(blogApi.list).mockResolvedValue([])
  })

  it('renders post content and the live vacancy widget', async () => {
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText('Phòng trọ đẹp')).toBeInTheDocument()
    await waitFor(() => expect(screen.getByText(/2\/5 phòng còn trống/i)).toBeInTheDocument())
  })

  it('renders room facts and the property sidebar', async () => {
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText('Thông tin phòng')).toBeInTheDocument()
    expect(screen.getByText('Phòng A101')).toBeInTheDocument()
    expect(screen.getByText('24 m²')).toBeInTheDocument()
    expect(screen.getByText('Bắc')).toBeInTheDocument()
    expect(screen.getByText('Nhà trọ Xanh')).toBeInTheDocument()
  })

  it('lists related posts from the same property, excluding the current post', async () => {
    vi.mocked(blogApi.list).mockResolvedValue([
      { id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp', coverImageUrl: null, roomId: 'r1', roomNumber: 'A101', roomStatus: 'EMPTY', propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi', publishedAt: null },
      { id: '2', slug: 'phong-khac', title: 'Phòng cùng nhà', coverImageUrl: null, roomId: 'r2', roomNumber: 'A102', roomStatus: 'RENTED', propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi', publishedAt: null },
      { id: '3', slug: 'phong-khac-nha', title: 'Phòng nhà khác', coverImageUrl: null, roomId: 'r3', roomNumber: 'B101', roomStatus: 'EMPTY', propertyId: 'p2', propertyName: 'Nhà trọ Đỏ', propertyAddress: '5 Trần Phú', publishedAt: null },
    ])

    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText('Các bài khác của tòa nhà này')).toBeInTheDocument()
    expect(screen.getByText('Phòng cùng nhà')).toBeInTheDocument()
    expect(screen.queryByText('Phòng nhà khác')).not.toBeInTheDocument()
  })

  it('shows a login prompt instead of the comment form when logged out', async () => {
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText(/đăng nhập để bình luận/i)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /gửi bình luận/i })).not.toBeInTheDocument()
  })

  it('shows the comment form when logged in', async () => {
    useAuthStore.setState({
      user: { id: 'u1', fullName: 'Khách A', email: 'a@example.com', role: 'GUEST', active: true },
    })

    renderAtSlug('phong-tro-dep')

    expect(await screen.findByRole('button', { name: /gửi bình luận/i })).toBeInTheDocument()
  })

  it('likes an unliked post by calling blogApi.like, not unlike', async () => {
    vi.mocked(blogApi.like).mockResolvedValue({ liked: true, likeCount: 4 })
    renderAtSlug('phong-tro-dep')

    fireEvent.click(await screen.findByRole('button', { name: /thích/i }))

    await waitFor(() => expect(blogApi.like).toHaveBeenCalledWith('phong-tro-dep'))
    expect(blogApi.unlike).not.toHaveBeenCalled()
  })

  it('unlikes an already-liked post by calling blogApi.unlike, not like', async () => {
    vi.mocked(blogApi.getBySlug).mockResolvedValue({ ...post, likeCount: 4, liked: true })
    vi.mocked(blogApi.unlike).mockResolvedValue({ liked: false, likeCount: 3 })
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByRole('button', { name: /đã thích/i })).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: /đã thích/i }))

    await waitFor(() => expect(blogApi.unlike).toHaveBeenCalledWith('phong-tro-dep'))
    expect(blogApi.like).not.toHaveBeenCalled()
  })
})
