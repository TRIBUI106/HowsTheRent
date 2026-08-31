import type { ReactNode } from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi, roomApi } from '@/api'
import AdminBlogEditorPage from './AdminBlogEditorPage'

const tiptap = vi.hoisted(() => ({
  editor: { getHTML: () => '<p>Nội dung</p>', commands: { setContent: vi.fn() } },
}))

vi.mock('@tiptap/react', () => ({
  useEditor: () => tiptap.editor,
  EditorContent: () => <div data-testid="editor-content" />,
}))
vi.mock('@tiptap/starter-kit', () => ({ default: {} }))
vi.mock('@/api', () => ({
  adminBlogApi: { get: vi.fn(), create: vi.fn(), update: vi.fn(), delete: vi.fn(), generateDraft: vi.fn(), uploadCoverImage: vi.fn(), publish: vi.fn(), unpublish: vi.fn() },
  roomApi: { listAll: vi.fn() },
}))

// See AdminBlogListPage.test.tsx for why Layout is shallow-mocked here.
vi.mock('@/components/Layout', () => ({
  default: ({ children }: { children: ReactNode }) => children,
}))

const editPost = {
  id: 'post-1', roomId: 'room-1', roomNumber: 'A101', propertyId: 'prop-1', propertyName: 'Nhà A',
  title: 'Bài viết cũ', slug: 'bai-viet-cu', content: '<p>Nội dung cũ</p>', coverImageUrl: null,
  published: false, publishedAt: null, authorId: null, authorName: null, createdAt: '', updatedAt: '',
}

function renderAtPath(path: string) {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={[path]}>
        <Routes>
          <Route path="/admin/blog/new" element={<AdminBlogEditorPage />} />
          <Route path="/admin/blog/:postId" element={<AdminBlogEditorPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('AdminBlogEditorPage', () => {
  beforeEach(() => {
    vi.mocked(adminBlogApi.get).mockReset()
    vi.mocked(adminBlogApi.create).mockReset()
    vi.mocked(adminBlogApi.update).mockReset()
    vi.mocked(adminBlogApi.delete).mockReset()
    vi.mocked(roomApi.listAll).mockResolvedValue([
      { id: 'room-1', propertyId: 'prop-1', propertyName: 'Nhà A', roomNumber: 'A101', maxPeople: 2, status: 'EMPTY', images: [], createdAt: '', updatedAt: '' },
    ])
  })

  it('saves an existing post by post ID', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue(editPost)
    vi.mocked(adminBlogApi.update).mockResolvedValue(editPost)

    renderAtPath('/admin/blog/post-1')
    expect(await screen.findByDisplayValue('Bài viết cũ')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText(/tiêu đề/i), { target: { value: 'Bài viết mới' } })
    fireEvent.click(screen.getByRole('button', { name: /lưu bài viết/i }))

    await waitFor(() => expect(adminBlogApi.update).toHaveBeenCalledWith('post-1', {
      title: 'Bài viết mới', slug: 'bai-viet-cu', content: '<p>Nội dung</p>', coverImageUrl: undefined,
    }))
  })

  it('creates a post for the selected room', async () => {
    vi.mocked(adminBlogApi.create).mockResolvedValue(editPost)

    renderAtPath('/admin/blog/new')
    await screen.findByRole('option', { name: 'Phòng A101' })
    const roomSelect = screen.getByRole('combobox') as HTMLSelectElement
    const valueSetter = Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, 'value')?.set
    valueSetter?.call(roomSelect, 'room-1')
    fireEvent.change(roomSelect, { target: { value: 'room-1' } })
    await waitFor(() => expect(roomSelect).toHaveValue('room-1'))
    fireEvent.change(screen.getByLabelText(/tiêu đề/i), { target: { value: 'Bài viết mới' } })
    fireEvent.click(screen.getByRole('button', { name: /tạo bản nháp$/i }))

    await waitFor(() => expect(adminBlogApi.create).toHaveBeenCalledWith({
      roomId: 'room-1', title: 'Bài viết mới', slug: undefined, content: '<p>Nội dung</p>', coverImageUrl: undefined,
    }))
  })

  it('fills the form from a room-scoped generated draft', async () => {
    vi.mocked(adminBlogApi.generateDraft).mockResolvedValue({
      title: 'Nhà A - Phòng A101', content: '<h2>Nhà A</h2>', coverImageUrl: null,
    })

    renderAtPath('/admin/blog/new')
    await screen.findByRole('option', { name: 'Phòng A101' })
    const roomSelect = screen.getByRole('combobox') as HTMLSelectElement
    const valueSetter = Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, 'value')?.set
    valueSetter?.call(roomSelect, 'room-1')
    fireEvent.change(roomSelect, { target: { value: 'room-1' } })
    await waitFor(() => expect(roomSelect).toHaveValue('room-1'))
    fireEvent.click(screen.getByRole('button', { name: /tạo bản nháp tự động/i }))

    await waitFor(() => expect(adminBlogApi.generateDraft).toHaveBeenCalledWith('room-1'))
    await waitFor(() => expect(screen.getByLabelText(/tiêu đề/i)).toHaveValue('Nhà A - Phòng A101'))
  })

  it('deletes an existing post only after confirmation', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue(editPost)
    vi.mocked(adminBlogApi.delete).mockResolvedValue(undefined)

    renderAtPath('/admin/blog/post-1')
    fireEvent.click(await screen.findByRole('button', { name: 'Xóa' }))

    expect(adminBlogApi.delete).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Xóa bài viết' }))
    await waitFor(() => expect(adminBlogApi.delete).toHaveBeenCalledWith('post-1'))
  })
})
