import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { userApi } from '@/api/userApi'
import { getErrorMessage } from '@/lib/apiError'
import { showToast } from '@/lib/toast'

export default function ChangePasswordPage() {
  const navigate = useNavigate()
  const [form, setForm] = useState({ currentPassword: '', newPassword: '', confirm: '' })
  const [error, setError] = useState('')

  const mutation = useGuardedMutation({
    mutationFn: () => userApi.changePassword({ currentPassword: form.currentPassword, newPassword: form.newPassword }),
    onSuccess: () => {
      showToast({ message: 'Mật khẩu đã được cập nhật', type: 'success' })
      navigate('/profile')
    },
    onError: (err: unknown) => {
      setError(getErrorMessage(err, 'Đổi mật khẩu thất bại'))
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    if (form.newPassword.length < 8) { setError('Mật khẩu mới phải có ít nhất 8 ký tự'); return }
    if (form.newPassword !== form.confirm) { setError('Mật khẩu xác nhận không khớp'); return }
    mutation.mutate()
  }

  return (
    <Layout title="Đổi mật khẩu">
      <div className="max-w-md">
        <Card>
          <CardHeader>Đổi mật khẩu</CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <Input
                label="Mật khẩu hiện tại"
                type="password"
                value={form.currentPassword}
                onChange={e => setForm({ ...form, currentPassword: e.target.value })}
                required
              />
              <Input
                label="Mật khẩu mới"
                type="password"
                value={form.newPassword}
                onChange={e => setForm({ ...form, newPassword: e.target.value })}
                required
                hint="Ít nhất 8 ký tự"
              />
              <Input
                label="Xác nhận mật khẩu mới"
                type="password"
                value={form.confirm}
                onChange={e => setForm({ ...form, confirm: e.target.value })}
                required
              />
              {error && <p className="text-sm text-error">{error}</p>}
              <Button type="submit" className="w-full" disabled={mutation.isPending}>
                {mutation.isPending ? 'Đang xử lý...' : 'Cập nhật mật khẩu'}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}
