import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import api from '@/lib/api'
import { useAuthStore } from '@/stores/authStore'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { CheckCircle } from 'lucide-react'
import logoHtr from '@/assets/logo-htr.png'

const brandPoints = [
  'Tự động tạo hóa đơn hàng tháng',
  'Theo dõi bảo trì theo thời gian thực',
  'Thanh toán trực tuyến qua PayOS',
  'Nhật ký hoạt động đầy đủ',
]

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const { setAuth } = useAuthStore()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const { data } = await api.post('/auth/login', { email, password })
      setAuth(data.user, data.accessToken, data.refreshToken)
      const role = data.user.role.toLowerCase()
      navigate(role === 'admin' ? '/admin' : role === 'tenant' ? '/tenant' : '/tech')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Email hoặc mật khẩu không đúng')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-bg flex">
      {/* Left: brand panel */}
      <div className="hidden lg:flex w-96 bg-fg flex-col justify-between p-10 shrink-0">
        <div>
          <div className="flex items-center gap-2.5 mb-12">
            <img src={logoHtr} alt="HowsTheRent" className="h-7 w-7 rounded-lg object-cover shrink-0" />
            <span className="font-semibold text-fg-inverted text-sm">HowsTheRent</span>
          </div>
          <h2 className="text-2xl font-bold text-fg-inverted tracking-tight mb-3 leading-snug">
            Quản lý nhà trọ<br />chuyên nghiệp
          </h2>
          <p className="text-sm text-fg-inverted-muted leading-relaxed mb-8">
            Hợp đồng, hóa đơn, bảo trì và thanh toán — tất cả trong một nền tảng.
          </p>
          <ul className="space-y-3">
            {brandPoints.map(item => (
              <li key={item} className="flex items-center gap-2.5 text-sm text-fg-inverted-muted">
                <CheckCircle className="w-4 h-4 text-success shrink-0" />
                {item}
              </li>
            ))}
          </ul>
        </div>
        <p className="text-xs text-fg-inverted-muted opacity-50">
          © {new Date().getFullYear()} HowsTheRent
        </p>
      </div>

      {/* Right: form */}
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="w-full max-w-sm">
          {/* Mobile logo */}
          <div className="flex items-center gap-2.5 mb-8 lg:hidden">
            <img src={logoHtr} alt="HowsTheRent" className="h-7 w-7 rounded-lg object-cover shrink-0" />
            <span className="font-semibold text-fg">HowsTheRent</span>
          </div>

          <h1 className="text-xl font-bold text-fg mb-1 tracking-tight">Đăng nhập</h1>
          <p className="text-sm text-fg-muted mb-7">Nhập thông tin tài khoản của bạn</p>

          <form onSubmit={handleSubmit} className="space-y-4" noValidate>
            <Input
              label="Email"
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="admin@example.com"
              required
              autoComplete="email"
              autoFocus
            />
            <Input
              label="Mật khẩu"
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              autoComplete="current-password"
            />
            {error && (
              <div className="flex items-start gap-2.5 p-3 bg-error-surface border border-error-border rounded-lg" role="alert">
                <svg className="w-4 h-4 text-error shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
                <p className="text-sm text-error-fg">{error}</p>
              </div>
            )}
            <Button type="submit" className="w-full mt-1" size="lg" loading={loading}>
              {loading ? 'Đang đăng nhập…' : 'Đăng nhập'}
            </Button>
          </form>

          <p className="text-center mt-5">
            <Link to="/forgot-password" className="text-sm text-accent hover:text-accent-hover transition-colors">
              Quên mật khẩu?
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
