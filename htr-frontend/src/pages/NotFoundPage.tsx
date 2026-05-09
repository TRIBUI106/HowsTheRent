import { Link } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'

export default function NotFoundPage() {
  const { user } = useAuthStore()
  const home = user?.role === 'ADMIN' ? '/admin' : user?.role === 'TENANT' ? '/tenant' : '/tech'

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <p className="text-7xl font-bold text-indigo-600 mb-4">404</p>
        <h1 className="text-2xl font-semibold text-gray-900 mb-2">Trang không tìm thấy</h1>
        <p className="text-gray-500 mb-8">Trang bạn đang tìm kiếm không tồn tại.</p>
        <Link
          to={home}
          className="inline-flex items-center gap-2 bg-indigo-600 text-white px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-indigo-700 transition-colors"
        >
          Về trang chủ
        </Link>
      </div>
    </div>
  )
}
