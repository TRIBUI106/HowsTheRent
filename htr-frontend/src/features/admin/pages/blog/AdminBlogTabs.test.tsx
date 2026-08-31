import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import AdminBlogTabs from './AdminBlogTabs'

function renderAt(pathname: string) {
  return render(
    <MemoryRouter initialEntries={[pathname]}>
      <Routes>
        <Route path="/admin/blog" element={<AdminBlogTabs />} />
        <Route path="/admin/blog/comments" element={<AdminBlogTabs />} />
      </Routes>
    </MemoryRouter>
  )
}

describe('AdminBlogTabs', () => {
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
})
