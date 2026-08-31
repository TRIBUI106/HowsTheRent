import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import { homePathForRole } from '@/lib/homePath'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

function getRegisterErrorMessage(error: unknown) {
  if (axios.isAxiosError(error)) {
    const message = error.response?.data?.message
    if (typeof message === 'string' && message.trim()) {
      return message
    }
  }
  return 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.'
}

export default function RegisterGuestPage() {
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const { setUser } = useAuthStore()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const { user } = await blogApi.registerGuest({ fullName, email, password })
      setUser(user)
      navigate(homePathForRole(user.role))
    } catch (err: unknown) {
      setError(getRegisterErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-bg px-6 py-12">
      <div className="w-full max-w-[420px]">
        <h1 className="text-2xl font-semibold tracking-[-0.03em] text-fg">Tạo tài khoản</h1>
        <p className="mt-2 text-sm text-fg-muted">Đăng ký để bình luận và thích bài viết.</p>

        <form onSubmit={handleSubmit} className="mt-8 space-y-5" noValidate>
          <Input
            label="Họ tên"
            value={fullName}
            onChange={e => setFullName(e.target.value)}
            required
            autoComplete="name"
          />
          <Input
            label="Email"
            aria-label="Email"
            type="email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            required
            autoComplete="email"
          />
          <Input
            label="Mật khẩu"
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            minLength={8}
            autoComplete="new-password"
          />

          {error && (
            <p className="rounded-xl border border-error-border bg-error-surface p-3 text-sm text-error-fg" role="alert">
              {error}
            </p>
          )}

          <Button type="submit" className="w-full" loading={loading}>
            {loading ? 'Đang đăng ký…' : 'Đăng ký'}
          </Button>
        </form>
      </div>
    </div>
  )
}
