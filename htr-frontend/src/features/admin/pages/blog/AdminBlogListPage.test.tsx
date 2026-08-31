import type { ReactNode } from 'react'
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import AdminBlogListPage from './AdminBlogListPage'

vi.mock('@/api', () => ({
  adminBlogApi: { listAll: vi.fn() },
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
  it('shows each property with its post status', async () => {
    vi.mocked(adminBlogApi.listAll).mockResolvedValue([
      { propertyId: 'p1', propertyName: 'Nhà A', postId: '1', title: 'Bài A', slug: 'bai-a', published: true, updatedAt: null },
      { propertyId: 'p2', propertyName: 'Nhà B', postId: null, title: null, slug: null, published: false, updatedAt: null },
    ])

    renderPage()

    expect(await screen.findByText('Nhà A')).toBeInTheDocument()
    expect(screen.getByText('Đã xuất bản')).toBeInTheDocument()
    expect(screen.getByText('Nhà B')).toBeInTheDocument()
    expect(screen.getByText('Chưa có bài viết')).toBeInTheDocument()
  })
})
