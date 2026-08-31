import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import AdminBlogCommentsPage from './AdminBlogCommentsPage'

vi.mock('@/api', () => ({
  adminBlogApi: { listComments: vi.fn(), deleteComment: vi.fn() },
}))

function renderPage() {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter><AdminBlogCommentsPage /></MemoryRouter>
    </QueryClientProvider>
  )
}

describe('AdminBlogCommentsPage', () => {
  beforeEach(() => {
    vi.mocked(adminBlogApi.listComments).mockResolvedValue([
      { id: 'c1', content: 'Spam link…', userId: 'u1', userName: 'Khách X', postId: 'p1', postTitle: 'Bài A', postSlug: 'bai-a', createdAt: '2026-08-01T00:00:00' },
    ])
    vi.mocked(adminBlogApi.deleteComment).mockResolvedValue(undefined)
  })

  it('lists comments with post context and deletes after confirmation', async () => {
    renderPage()

    expect(await screen.findByText('Spam link…')).toBeInTheDocument()
    expect(screen.getByText('Bài A')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /xóa/i }))
    expect(await screen.findByText(/xóa bình luận này/i)).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /xác nhận xóa/i }))

    await waitFor(() => expect(adminBlogApi.deleteComment).toHaveBeenCalledWith('c1'))
  })
})
