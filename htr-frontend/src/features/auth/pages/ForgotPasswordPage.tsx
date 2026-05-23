import { useState } from 'react'
import { Link } from 'react-router-dom'
import api from '@/lib/api'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import logoHtr from '@/assets/logo-htr.png'
import { Mail } from 'lucide-react'

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      await api.post('/auth/forgot-password', { email })
      setSent(true)
    } catch {
      setError('Email không tồn tại trong hệ thống')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <div className="w-full max-w-sm bg-surface rounded-2xl shadow-[0_1px_3px_rgba(15,23,42,0.06)] border border-border/80 p-8 animate-scale-in">
        <div className="text-center mb-6">
          <img src={logoHtr} alt="HowsTheRent" className="mx-auto mb-3 h-10 w-10 rounded-xl object-cover shadow-[0_1px_2px_rgba(15,23,42,0.08)]" />
          <h1 className="text-xl font-semibold text-fg">Quên mật khẩu</h1>
          <p className="text-sm text-fg-muted mt-1">Nhập email để nhận mã OTP</p>
        </div>
        {sent ? (
          <div className="text-center space-y-4 animate-fade-in">
            <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-accent-surface text-accent">
              <Mail className="h-6 w-6" />
            </div>
            <p className="text-sm text-fg-muted">Mã OTP đã được gửi về <strong className="text-fg">{email}</strong>. Kiểm tra hộp thư và nhập mã để đặt lại mật khẩu.</p>
            <Link
              to="/reset-password"
              state={{ email }}
              className="block w-full text-center bg-accent text-accent-fg py-2.5 rounded-xl text-sm font-medium hover:bg-accent-hover transition-colors"
            >
              Nhập mã OTP
            </Link>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <Input label="Email" type="email" value={email} onChange={e => setEmail(e.target.value)} required placeholder="admin@example.com" />
            {error && <p className="text-sm text-error">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? 'Đang gửi...' : 'Gửi mã OTP'}
            </Button>
          </form>
        )}
        <p className="text-center text-sm text-fg-muted mt-4">
          <Link to="/login" className="text-accent hover:underline">&larr; Quay lại đăng nhập</Link>
        </p>
      </div>
    </div>
  )
}
