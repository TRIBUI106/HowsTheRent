import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import axios from 'axios'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { BarChart3, CreditCard, Home, Wrench } from 'lucide-react'
import logoHtr from '@/assets/logo-htr.png'

const systemHighlights = [
  { icon: Home, label: 'Quản lý phòng và hợp đồng' },
  { icon: CreditCard, label: 'Theo dõi công nợ, thanh toán' },
  { icon: Wrench, label: 'Ghi nhận bảo trì và vận hành' },
  { icon: BarChart3, label: 'Tổng quan dữ liệu theo thời gian thực' },
]

function getLoginErrorMessage(error: unknown) {
  if (axios.isAxiosError(error)) {
    const message = error.response?.data?.message
    if (typeof message === 'string' && message.trim()) {
      return message
    }

    if (error.response?.status === 400 || error.response?.status === 401) {
      return 'Email hoặc mật khẩu không đúng'
    }
  }

  return 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.'
}

export default function LoginPage() {
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
      await api.post('/auth/login', { email, password })
      const { data } = await api.get('/users/me')
      setUser(data)
      const role = data.role.toLowerCase()
      navigate(role === 'admin' ? '/admin' : role === 'tenant' ? '/tenant' : '/tech')
    } catch (err: any) {
      setError(getLoginErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-bg text-fg">
      <main className="grid min-h-screen grid-cols-1 lg:grid-cols-[30%_70%]">

        {/* System Highlights */}

        <section className="relative overflow-hidden border-b border-border bg-[linear-gradient(135deg,var(--color-accent-surface)_0%,var(--color-accent-surface)_48%,var(--color-bg)_52%,var(--color-surface)_100%)] px-6 py-8 lg:border-b-0 lg:border-r lg:px-8 lg:py-10">
          <div className="absolute inset-0 opacity-35 [background-image:linear-gradient(var(--color-accent)_1px,transparent_1px),linear-gradient(90deg,var(--color-accent)_1px,transparent_1px)] [background-size:28px_28px]" />
          <div className="absolute -left-24 top-16 h-72 w-72 rounded-full bg-accent/24 blur-3xl" />
          <div className="absolute bottom-[-7rem] right-[-5rem] h-72 w-72 rounded-full bg-bg/75 blur-3xl" />

          <div className="relative flex h-full min-h-[320px] flex-col justify-between lg:min-h-0">
            <div className="flex items-center gap-3">
              <img src={logoHtr} alt="HowsTheRent" className="h-10 w-10 rounded-2xl object-cover shadow-sm ring-1 ring-border" />
              <div>
                <p className="text-sm font-semibold leading-none text-fg">HowsTheRent</p>
                <p className="mt-1 text-xs text-fg-subtle">Rental operations workspace</p>
              </div>
            </div>

            <div className="py-10 lg:py-0">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-accent">Hệ thống quản lý nhà trọ</p>
              <h1 className="mt-5 max-w-sm text-4xl font-semibold leading-[1.02] tracking-[-0.05em] text-fg lg:text-[42px]">
                Một nơi gọn gàng cho toàn bộ vận hành thuê trọ.
              </h1>
              <p className="mt-5 max-w-sm text-sm leading-7 text-fg-muted">
                Từ phòng, hợp đồng, hóa đơn đến bảo trì — mọi dữ liệu được gom lại để chủ trọ xử lý nhanh và rõ ràng hơn mỗi ngày.
              </p>
            </div>

            <div className="space-y-3">
              {systemHighlights.map(item => {
                const Icon = item.icon
                return (
                  <div key={item.label} className="flex items-center gap-3 rounded-2xl border border-border/80 bg-surface/65 px-3.5 py-3 shadow-sm backdrop-blur-md">
                    <span className="inline-flex h-8 w-8 items-center justify-center rounded-xl bg-accent-surface text-accent">
                      <Icon size={15} />
                    </span>
                    <span className="text-sm text-fg-muted">{item.label}</span>
                  </div>
                )
              })}
            </div>
          </div>
        </section>

        {/* Login Form */}

        <section className="flex min-h-[calc(100vh-320px)] items-center justify-center bg-surface px-6 py-12 sm:px-10 lg:min-h-screen">
          <div className="w-full max-w-[420px]">
            <div className="mb-9">
              <h2 className="text-[30px] font-semibold leading-tight tracking-[-0.04em] text-fg">Đăng nhập</h2>
              <p className="mt-3 text-sm leading-6 text-fg-muted">Nhập tài khoản để tiếp tục vào dashboard quản lý.</p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-5" noValidate>
              <Input
                label="Email"
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="admin@example.com"
                required
                autoComplete="email"
                autoFocus
                className="min-h-[48px] rounded-xl bg-bg"
              />

              <div className="space-y-2">
                <Input
                  label="Mật khẩu"
                  type="password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  autoComplete="current-password"
                  className="min-h-[48px] rounded-xl bg-bg"
                />
                <div className="flex justify-end">
                  <Link to="/forgot-password" className="text-xs font-medium text-accent transition-colors hover:text-accent-hover">
                    Quên mật khẩu?
                  </Link>
                </div>
              </div>

              {error && (
                <div className="flex items-start gap-2.5 rounded-2xl border border-error-border bg-error-surface p-3" role="alert">
                  <svg className="mt-0.5 h-4 w-4 shrink-0 text-error" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                  </svg>
                  <p className="text-sm text-error-fg">{error}</p>
                </div>
              )}

              <Button type="submit" className="w-full rounded-xl" size="lg" loading={loading}>
                {loading ? 'Đang đăng nhập…' : 'Đăng nhập'}
              </Button>
            </form>

            <p className="mt-8 border-t border-border pt-6 text-xs leading-5 text-fg-subtle text-center">
              © {new Date().getFullYear()} HowsTheRent
            </p>
          </div>
        </section>
      </main>
    </div>
  )
}
