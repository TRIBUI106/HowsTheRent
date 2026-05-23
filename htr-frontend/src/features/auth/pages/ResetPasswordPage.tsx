import { useState } from 'react'
import { useNavigate, useLocation, Link } from 'react-router-dom'
import api from '@/lib/api'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import logoHtr from '@/assets/logo-htr.png'

export default function ResetPasswordPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const prefillEmail = (location.state as any)?.email ?? ''

  const [form, setForm] = useState({ email: prefillEmail, otp: '', newPassword: '', confirm: '' })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (form.newPassword !== form.confirm) { setError('Mật khẩu xác nhận không khớp'); return }
    setLoading(true)
    setError('')
    try {
      await api.post('/auth/reset-password', { email: form.email, otp: form.otp, newPassword: form.newPassword })
      navigate('/login', { state: { message: 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.' } })
    } catch {
      setError('OTP không hợp lệ hoặc đã hết hạn')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <div className="w-full max-w-sm bg-surface rounded-2xl shadow-[0_1px_3px_rgba(15,23,42,0.06)] border border-border/80 p-8 animate-scale-in">
        <div className="text-center mb-6">
          <img src={logoHtr} alt="HowsTheRent" className="mx-auto mb-3 h-10 w-10 rounded-xl object-cover shadow-[0_1px_2px_rgba(15,23,42,0.08)]" />
          <h1 className="text-xl font-semibold text-fg">Đặt lại mật khẩu</h1>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input label="Email" type="email" value={form.email} onChange={e => setForm({...form, email: e.target.value})} required />
          <Input label="Mã OTP" value={form.otp} onChange={e => setForm({...form, otp: e.target.value})} required placeholder="6 chữ số" />
          <Input label="Mật khẩu mới" type="password" value={form.newPassword} onChange={e => setForm({...form, newPassword: e.target.value})} required />
          <Input label="Xác nhận mật khẩu" type="password" value={form.confirm} onChange={e => setForm({...form, confirm: e.target.value})} required />
          {error && <p className="text-sm text-error">{error}</p>}
          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? 'Đang xử lý...' : 'Đặt lại mật khẩu'}
          </Button>
        </form>
        <p className="text-center text-sm text-fg-muted mt-4">
          <Link to="/login" className="text-accent hover:underline">&larr; Quay lại đăng nhập</Link>
        </p>
      </div>
    </div>
  )
}
