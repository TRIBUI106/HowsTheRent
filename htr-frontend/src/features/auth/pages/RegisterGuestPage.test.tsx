import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import RegisterGuestPage from './RegisterGuestPage'

vi.mock('@/api', () => ({
  blogApi: { registerGuest: vi.fn() },
}))

describe('RegisterGuestPage', () => {
  beforeEach(() => {
    useAuthStore.setState({ user: null })
  })

  it('registers and logs the guest in on submit', async () => {
    vi.mocked(blogApi.registerGuest).mockResolvedValue({
      accessToken: 'a', refreshToken: 'r',
      user: { id: 'u1', fullName: 'Khách A', email: 'a@example.com', role: 'GUEST', active: true },
    })

    render(<MemoryRouter><RegisterGuestPage /></MemoryRouter>)

    fireEvent.change(screen.getByLabelText(/họ tên/i), { target: { value: 'Khách A' } })
    fireEvent.change(screen.getByLabelText(/^email$/i), { target: { value: 'a@example.com' } })
    fireEvent.change(screen.getByLabelText(/^mật khẩu\s*\*?$/i), { target: { value: 'Password1!' } })
    fireEvent.click(screen.getByRole('button', { name: /đăng ký/i }))

    await waitFor(() => expect(blogApi.registerGuest).toHaveBeenCalledWith({
      fullName: 'Khách A', email: 'a@example.com', password: 'Password1!',
    }))
    await waitFor(() => expect(useAuthStore.getState().user?.role).toBe('GUEST'))
  })

  it('shows an error message when the email is already taken', async () => {
    vi.mocked(blogApi.registerGuest).mockRejectedValue({
      isAxiosError: true,
      response: { status: 400, data: { message: 'Email đã được sử dụng' } },
    })

    render(<MemoryRouter><RegisterGuestPage /></MemoryRouter>)

    fireEvent.change(screen.getByLabelText(/họ tên/i), { target: { value: 'Khách A' } })
    fireEvent.change(screen.getByLabelText(/^email$/i), { target: { value: 'a@example.com' } })
    fireEvent.change(screen.getByLabelText(/^mật khẩu\s*\*?$/i), { target: { value: 'Password1!' } })
    fireEvent.click(screen.getByRole('button', { name: /đăng ký/i }))

    expect(await screen.findByText('Email đã được sử dụng')).toBeInTheDocument()
  })
})
