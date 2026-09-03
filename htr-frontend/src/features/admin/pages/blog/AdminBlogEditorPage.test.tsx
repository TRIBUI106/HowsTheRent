import type { ReactNode } from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi, roomApi } from '@/api'
import AdminBlogEditorPage from './AdminBlogEditorPage'

const tiptap = vi.hoisted(() => {
  const chain = {
    focus: vi.fn(() => chain),
    toggleBold: vi.fn(() => chain),
    toggleItalic: vi.fn(() => chain),
    toggleStrike: vi.fn(() => chain),
    toggleHeading: vi.fn(() => chain),
    toggleBulletList: vi.fn(() => chain),
    toggleOrderedList: vi.fn(() => chain),
    toggleBlockquote: vi.fn(() => chain),
    undo: vi.fn(() => chain),
    redo: vi.fn(() => chain),
    run: vi.fn(),
  }
  return {
    chain,
    editor: {
      getHTML: () => '<p>Nội dung</p>',
      commands: { setContent: vi.fn() },
      chain: vi.fn(() => chain),
      isActive: vi.fn(() => false),
      can: vi.fn(() => ({ undo: () => true, redo: () => true })),
    },
  }
})

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
  published: false, publishedAt: null, authorId: null, authorName: null, createdAt: '', updatedAt: '', tags: [],
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
    vi.mocked(adminBlogApi.uploadCoverImage).mockReset()
    tiptap.chain.run.mockClear()
    tiptap.editor.chain.mockClear()
    tiptap.editor.isActive.mockReset().mockReturnValue(false)
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
      title: 'Bài viết mới', slug: 'bai-viet-cu', content: '<p>Nội dung</p>', coverImageUrl: undefined, publishAt: undefined, tags: [],
    }))
  })

  it('shows the schedule input for an unpublished post and sends the scheduled time on save', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue(editPost)
    vi.mocked(adminBlogApi.update).mockResolvedValue(editPost)

    renderAtPath('/admin/blog/post-1')
    await screen.findByDisplayValue('Bài viết cũ')

    const scheduleInput = screen.getByLabelText(/lên lịch xuất bản/i)
    fireEvent.change(scheduleInput, { target: { value: '2026-12-01T10:00' } })
    expect(screen.getByText(/sẽ tự động xuất bản lúc/i)).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /lưu bài viết/i }))

    await waitFor(() => expect(adminBlogApi.update).toHaveBeenCalledWith('post-1', {
      title: 'Bài viết cũ', slug: 'bai-viet-cu', content: '<p>Nội dung</p>', coverImageUrl: undefined, publishAt: '2026-12-01T10:00:00', tags: [],
    }))
  })

  it('hides the schedule input once a post is published', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue({ ...editPost, published: true })

    renderAtPath('/admin/blog/post-1')
    await screen.findByDisplayValue('Bài viết cũ')

    expect(screen.queryByLabelText(/lên lịch xuất bản/i)).not.toBeInTheDocument()
  })

  it('labels a vacant room with a Trống suffix, leaving other statuses unchanged', async () => {
    vi.mocked(roomApi.listAll).mockResolvedValue([
      { id: 'room-1', propertyId: 'prop-1', propertyName: 'Nhà A', roomNumber: 'A101', maxPeople: 2, status: 'EMPTY', images: [], createdAt: '', updatedAt: '' },
      { id: 'room-2', propertyId: 'prop-1', propertyName: 'Nhà A', roomNumber: 'A102', maxPeople: 2, status: 'RENTED', images: [], createdAt: '', updatedAt: '' },
    ])

    renderAtPath('/admin/blog/new')

    expect(await screen.findByRole('option', { name: 'Phòng A101 · Trống' })).toBeInTheDocument()
    expect(screen.getByRole('option', { name: 'Phòng A102' })).toBeInTheDocument()
  })

  it('creates a post for the selected room', async () => {
    vi.mocked(adminBlogApi.create).mockResolvedValue(editPost)

    renderAtPath('/admin/blog/new')
    await screen.findByRole('option', { name: 'Phòng A101 · Trống' })
    const roomSelect = screen.getByRole('combobox') as HTMLSelectElement
    const valueSetter = Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, 'value')?.set
    valueSetter?.call(roomSelect, 'room-1')
    fireEvent.change(roomSelect, { target: { value: 'room-1' } })
    await waitFor(() => expect(roomSelect).toHaveValue('room-1'))
    fireEvent.change(screen.getByLabelText(/tiêu đề/i), { target: { value: 'Bài viết mới' } })
    fireEvent.click(screen.getByRole('button', { name: /tạo bản nháp$/i }))

    await waitFor(() => expect(adminBlogApi.create).toHaveBeenCalledWith({
      roomId: 'room-1', title: 'Bài viết mới', slug: undefined, content: '<p>Nội dung</p>', coverImageUrl: undefined, publishAt: undefined, tags: [],
    }))
  })

  it('fills the form from a room-scoped generated draft', async () => {
    vi.mocked(adminBlogApi.generateDraft).mockResolvedValue({
      title: 'Nhà A - Phòng A101', content: '<h2>Nhà A</h2>', coverImageUrl: null,
    })

    renderAtPath('/admin/blog/new')
    await screen.findByRole('option', { name: 'Phòng A101 · Trống' })
    const roomSelect = screen.getByRole('combobox') as HTMLSelectElement
    const valueSetter = Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, 'value')?.set
    valueSetter?.call(roomSelect, 'room-1')
    fireEvent.change(roomSelect, { target: { value: 'room-1' } })
    await waitFor(() => expect(roomSelect).toHaveValue('room-1'))
    fireEvent.click(screen.getByRole('button', { name: /tạo bản nháp tự động/i }))

    await waitFor(() => expect(adminBlogApi.generateDraft).toHaveBeenCalledWith('room-1'))
    await waitFor(() => expect(screen.getByLabelText(/tiêu đề/i)).toHaveValue('Nhà A - Phòng A101'))
  })

  it('uploads a dropped file as the cover image', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue(editPost)
    vi.mocked(adminBlogApi.uploadCoverImage).mockResolvedValue({ ...editPost, coverImageUrl: 'https://cdn.example.com/cover.jpg' })

    renderAtPath('/admin/blog/post-1')
    const dropzone = await screen.findByTestId('cover-image-dropzone')

    const file = new File(['data'], 'cover.jpg', { type: 'image/jpeg' })
    fireEvent.drop(dropzone, { dataTransfer: { files: [file] } })

    await waitFor(() => expect(adminBlogApi.uploadCoverImage).toHaveBeenCalledWith('post-1', file))
  })

  it('rejects a dropped non-image file without calling the upload API', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue(editPost)

    renderAtPath('/admin/blog/post-1')
    const dropzone = await screen.findByTestId('cover-image-dropzone')

    const file = new File(['data'], 'notes.txt', { type: 'text/plain' })
    fireEvent.drop(dropzone, { dataTransfer: { files: [file] } })

    expect(adminBlogApi.uploadCoverImage).not.toHaveBeenCalled()
  })

  it('adds tags on Enter, removes them via the chip X button, and includes them in the save payload', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue(editPost)
    vi.mocked(adminBlogApi.update).mockResolvedValue(editPost)

    renderAtPath('/admin/blog/post-1')
    await screen.findByDisplayValue('Bài viết cũ')

    const tagInput = screen.getByPlaceholderText('Nhập tag rồi nhấn Enter')
    fireEvent.change(tagInput, { target: { value: 'gia-re' } })
    fireEvent.keyDown(tagInput, { key: 'Enter' })
    fireEvent.change(tagInput, { target: { value: 'trung-tam' } })
    fireEvent.keyDown(tagInput, { key: 'Enter' })

    expect(screen.getByText('gia-re')).toBeInTheDocument()
    expect(screen.getByText('trung-tam')).toBeInTheDocument()
    expect(tagInput).toHaveValue('')

    fireEvent.click(screen.getByRole('button', { name: 'Xóa tag gia-re' }))
    expect(screen.queryByText('gia-re')).not.toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /lưu bài viết/i }))

    await waitFor(() => expect(adminBlogApi.update).toHaveBeenCalledWith('post-1', {
      title: 'Bài viết cũ', slug: 'bai-viet-cu', content: '<p>Nội dung</p>', coverImageUrl: undefined, publishAt: undefined, tags: ['trung-tam'],
    }))
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

  it('applies bold formatting via the toolbar', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue(editPost)

    renderAtPath('/admin/blog/post-1')
    fireEvent.click(await screen.findByRole('button', { name: 'Đậm' }))

    expect(tiptap.chain.toggleBold).toHaveBeenCalled()
    expect(tiptap.chain.run).toHaveBeenCalled()
  })

  it('highlights the toolbar button matching the current selection', async () => {
    vi.mocked(adminBlogApi.get).mockResolvedValue(editPost)
    tiptap.editor.isActive.mockImplementation((...args: unknown[]) => args[0] === 'bold')

    renderAtPath('/admin/blog/post-1')
    const boldButton = await screen.findByRole('button', { name: 'Đậm' })
    const italicButton = screen.getByRole('button', { name: 'Nghiêng' })

    expect(boldButton.className).toContain('text-accent')
    expect(italicButton.className).not.toContain('text-accent')
  })
})
