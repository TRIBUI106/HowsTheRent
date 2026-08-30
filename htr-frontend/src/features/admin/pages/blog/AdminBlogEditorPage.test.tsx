import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import AdminBlogEditorPage from './AdminBlogEditorPage'

vi.mock('@tiptap/react', () => ({
  useEditor: () => ({ getHTML: () => '<p>Nội dung</p>', commands: { setContent: vi.fn() } }),
  EditorContent: () => <div data-testid="editor-content" />,
}))
vi.mock('@tiptap/starter-kit', () => ({ default: {} }))
vi.mock('@/api', () => ({
  adminBlogApi: { get: vi.fn(), update: vi.fn(), generateDraft: vi.fn(), uploadCoverImage: vi.fn(), publish: vi.fn(), unpublish: vi.fn() },
}))

function mockNotFound() {
  vi.mocked(adminBlogApi.get).mockRejectedValue({ isAxiosError: true, response: { status: 404 } })
}

function renderAtProperty(propertyId: string) {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={[`/admin/blog/${propertyId}`]}>
        <Routes>
          <Route path="/admin/blog/:propertyId" element={<AdminBlogEditorPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('AdminBlogEditorPage', () => {
  beforeEach(() => {
    vi.mocked(adminBlogApi.get).mockReset()
    window.addEventListener('unhandledrejection', event => event.preventDefault(), { once: true })
  })

  it('shows a not-yet-created hint when no post exists for the property', async () => {
    mockNotFound()

    renderAtProperty('prop-1')

    expect(await screen.findByText(/chưa có bài viết/i)).toBeInTheDocument()
  })

  it('saves the title and generated content on submit', async () => {
    mockNotFound()
    vi.mocked(adminBlogApi.update).mockResolvedValue({
      id: '1', propertyId: 'prop-1', propertyName: 'Nhà A', title: 'Bài viết mới', slug: 'bai-viet-moi',
      content: '<p>Nội dung</p>', coverImageUrl: null, published: false, publishedAt: null,
      authorId: null, authorName: null, createdAt: '', updatedAt: '',
    })

    renderAtProperty('prop-1')
    await screen.findByText(/chưa có bài viết/i)

    fireEvent.change(screen.getByLabelText(/tiêu đề/i), { target: { value: 'Bài viết mới' } })
    await waitFor(() => expect(screen.getByLabelText(/tiêu đề/i)).toHaveValue('Bài viết mới'))
    fireEvent.click(screen.getByRole('button', { name: /lưu bài viết/i }))

    await waitFor(() => expect(adminBlogApi.update).toHaveBeenCalledWith('prop-1', {
      title: 'Bài viết mới', slug: undefined, content: '<p>Nội dung</p>', coverImageUrl: undefined,
    }))
  })

  it('fills the title from the generated draft', async () => {
    mockNotFound()
    vi.mocked(adminBlogApi.generateDraft).mockResolvedValue({
      title: 'Nhà A - Cho thuê phòng trọ', content: '<h2>Nhà A</h2>', coverImageUrl: null,
    })

    renderAtProperty('prop-1')
    await screen.findByText(/chưa có bài viết/i)

    fireEvent.click(screen.getByRole('button', { name: /tạo bản nháp tự động/i }))

    await waitFor(() => expect(screen.getByLabelText(/tiêu đề/i)).toHaveValue('Nhà A - Cho thuê phòng trọ'))
  })
})
