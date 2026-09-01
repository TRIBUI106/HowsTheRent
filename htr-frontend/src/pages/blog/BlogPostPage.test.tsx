import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent, within } from '@testing-library/react'
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
  likeCount: 3, liked: false, tags: [],
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
    expect(screen.getByText(/toàn bộ nhà trọ/i)).toBeInTheDocument()
  })

  it('shows a skeleton over the cover image until it loads', async () => {
    vi.mocked(blogApi.getBySlug).mockResolvedValue({ ...post, coverImageUrl: 'https://example.test/cover.jpg' })
    renderAtSlug('phong-tro-dep')

    await screen.findByText('Phòng trọ đẹp')
    expect(screen.getAllByTestId('image-skeleton').length).toBeGreaterThan(0)

    const coverImg = screen.getAllByAltText('').find(
      img => (img as HTMLImageElement).src === 'https://example.test/cover.jpg'
    ) as HTMLImageElement
    fireEvent.load(coverImg)

    expect(coverImg).toHaveClass('opacity-100')
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
      { id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp', coverImageUrl: null, roomId: 'r1', roomNumber: 'A101', roomStatus: 'EMPTY', propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi', publishedAt: null, tags: [] },
      { id: '2', slug: 'phong-khac', title: 'Phòng cùng nhà', coverImageUrl: null, roomId: 'r2', roomNumber: 'A102', roomStatus: 'RENTED', propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi', publishedAt: null, tags: [] },
      { id: '3', slug: 'phong-khac-nha', title: 'Phòng nhà khác', coverImageUrl: null, roomId: 'r3', roomNumber: 'B101', roomStatus: 'EMPTY', propertyId: 'p2', propertyName: 'Nhà trọ Đỏ', propertyAddress: '5 Trần Phú', publishedAt: null, tags: [] },
    ])

    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText('Các bài khác của tòa nhà này')).toBeInTheDocument()
    expect(screen.getByText('Phòng cùng nhà')).toBeInTheDocument()
    expect(screen.queryByText('Phòng nhà khác')).not.toBeInTheDocument()
  })

  it('renders the post\'s tags below the title when present', async () => {
    vi.mocked(blogApi.getBySlug).mockResolvedValue({ ...post, tags: ['gia-re', 'trung-tam'] })
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText('gia-re')).toBeInTheDocument()
    expect(screen.getByText('trung-tam')).toBeInTheDocument()
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

  it('flips the like button and count immediately, before the API call resolves', async () => {
    let resolveLike!: (value: { liked: boolean; likeCount: number }) => void
    vi.mocked(blogApi.like).mockReturnValue(new Promise(resolve => { resolveLike = resolve }))
    renderAtSlug('phong-tro-dep')

    fireEvent.click(await screen.findByRole('button', { name: /^♡ Thích · 3$/ }))

    // Optimistic update lands synchronously via onMutate, ahead of the pending mock promise.
    expect(await screen.findByRole('button', { name: /^♥ Đã thích · 4$/ })).toBeInTheDocument()

    resolveLike({ liked: true, likeCount: 4 })
    await waitFor(() => expect(blogApi.like).toHaveBeenCalledWith('phong-tro-dep'))
  })

  it('rolls back the like button and count if the API call fails', async () => {
    let rejectLike!: (err: unknown) => void
    vi.mocked(blogApi.like).mockReturnValue(new Promise((_resolve, reject) => { rejectLike = reject }))
    renderAtSlug('phong-tro-dep')

    fireEvent.click(await screen.findByRole('button', { name: /^♡ Thích · 3$/ }))
    expect(await screen.findByRole('button', { name: /^♥ Đã thích · 4$/ })).toBeInTheDocument()

    rejectLike(new Error('boom'))
    expect(await screen.findByRole('button', { name: /^♡ Thích · 3$/ })).toBeInTheDocument()
  })

  it('shows a new comment immediately, dimmed, before the API call resolves, then undims it', async () => {
    useAuthStore.setState({
      user: { id: 'u1', fullName: 'Khách A', email: 'a@example.com', role: 'GUEST', active: true },
    })
    let resolveAddComment!: (value: { id: string; content: string; userId: string; userName: string; createdAt: string }) => void
    vi.mocked(blogApi.addComment).mockReturnValue(new Promise(resolve => { resolveAddComment = resolve }))
    renderAtSlug('phong-tro-dep')

    const textarea = await screen.findByPlaceholderText('Viết bình luận…')
    fireEvent.change(textarea, { target: { value: 'Rất đẹp' } })
    fireEvent.click(screen.getByRole('button', { name: /gửi bình luận/i }))

    // Optimistic entry appears immediately, dimmed, and the textarea clears right away.
    // Query within the comment list (not the whole document) — a <textarea>'s live
    // value is itself text-matchable in jsdom, so an unscoped query can spuriously
    // match the textarea instead of/alongside the rendered comment.
    const list = screen.getByRole('list')
    const optimisticComment = await within(list).findByText('Rất đẹp')
    expect(optimisticComment.closest('li')).toHaveClass('opacity-50')
    expect(textarea).toHaveValue('')

    const saved = { id: 'c1', content: 'Rất đẹp', userId: 'u1', userName: 'Khách A', createdAt: '2026-09-01T00:00:00Z' }
    vi.mocked(blogApi.listComments).mockResolvedValue([saved])
    resolveAddComment(saved)

    // The invalidate-driven refetch replaces the temp entry with the confirmed (undimmed) one.
    await waitFor(() => expect(within(list).getByText('Rất đẹp').closest('li')).not.toHaveClass('opacity-50'))
  })

  it('removes the optimistic comment and restores the typed text if the API call fails', async () => {
    useAuthStore.setState({
      user: { id: 'u1', fullName: 'Khách A', email: 'a@example.com', role: 'GUEST', active: true },
    })
    let rejectAddComment!: (err: unknown) => void
    vi.mocked(blogApi.addComment).mockReturnValue(new Promise((_resolve, reject) => { rejectAddComment = reject }))
    renderAtSlug('phong-tro-dep')

    const textarea = await screen.findByPlaceholderText('Viết bình luận…')
    fireEvent.change(textarea, { target: { value: 'Rất đẹp' } })
    fireEvent.click(screen.getByRole('button', { name: /gửi bình luận/i }))

    // Scoped to the list, as above — after rollback the textarea's own restored value
    // would otherwise be a false-positive match for an unscoped text query.
    const list = screen.getByRole('list')
    await within(list).findByText('Rất đẹp')

    rejectAddComment(new Error('boom'))

    await waitFor(() => expect(within(list).queryByText('Rất đẹp')).not.toBeInTheDocument())
    expect(textarea).toHaveValue('Rất đẹp')
  })

  function countImagesWithSrc(src: string) {
    return screen.queryAllByAltText('').filter(img => (img as HTMLImageElement).src === src).length
  }

  it('opens a lightbox with the full-size image when a room thumbnail is clicked', async () => {
    renderAtSlug('phong-tro-dep')

    await screen.findByRole('button', { name: /xem ảnh phòng lớn hơn/i })
    expect(countImagesWithSrc(post.roomImages[0])).toBe(1) // just the thumbnail

    fireEvent.click(screen.getByRole('button', { name: /xem ảnh phòng lớn hơn/i }))

    await waitFor(() => expect(countImagesWithSrc(post.roomImages[0])).toBe(2)) // thumbnail + lightbox
  })

  it('closes the lightbox when the close button is clicked', async () => {
    renderAtSlug('phong-tro-dep')

    fireEvent.click(await screen.findByRole('button', { name: /xem ảnh phòng lớn hơn/i }))
    expect(await screen.findByRole('button', { name: 'Đóng' })).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Đóng' }))

    expect(countImagesWithSrc(post.roomImages[0])).toBe(1) // back to just the thumbnail
  })
})
