import { Link } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'

export default function NotFoundPage() {
  const { user } = useAuthStore()
  const home = user?.role === 'ADMIN' ? '/admin' : user?.role === 'TENANT' ? '/tenant' : '/tech'

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center">
      <div className="text-center animate-scale-in">
        <p className="text-7xl font-bold text-accent mb-4">404</p>
        <h1 className="text-2xl font-semibold text-fg mb-2">Trang không tìm thấy</h1>
        <p className="text-fg-muted mb-8">Trang bạn đang tìm kiếm không tồn tại.</p>
        <Link
          to={home}
          className="inline-flex items-center gap-2 bg-accent text-accent-fg px-5 py-2.5 rounded-xl text-sm font-medium hover:bg-accent-hover transition-colors"
        >
          Về trang chủ
        </Link>
      </div>
    </div>
  )
}
