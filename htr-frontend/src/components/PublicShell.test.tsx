import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import PublicShell from './PublicShell'

describe('PublicShell', () => {
  it('renders the nav login link, footer copyright, and children', () => {
    render(
      <MemoryRouter>
        <PublicShell>
          <p>Nội dung trang</p>
        </PublicShell>
      </MemoryRouter>
    )

    expect(screen.getByRole('link', { name: /đăng nhập/i })).toHaveAttribute('href', '/login')
    expect(screen.getByText(/Nội dung trang/)).toBeInTheDocument()
    expect(screen.getByText(new RegExp(`© ${new Date().getFullYear()} HowsTheRent`))).toBeInTheDocument()
  })
})
