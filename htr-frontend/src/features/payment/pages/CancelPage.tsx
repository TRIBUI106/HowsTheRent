import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'

export default function PaymentCancelPage() {
  const navigate = useNavigate()
  const { user } = useAuthStore()

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-lg p-8 max-w-md w-full text-center space-y-4">
        <div className="flex items-center justify-center w-16 h-16 mx-auto bg-yellow-100 rounded-full">
          <svg className="w-8 h-8 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-gray-900">Thanh toán bị hủy</h1>
        <p className="text-gray-500">
          Bạn đã hủy giao dịch. Hóa đơn vẫn chưa được thanh toán.
        </p>
        <div className="flex gap-3 pt-2">
          <button
            onClick={() => navigate(-1)}
            className="flex-1 border border-gray-300 text-gray-700 rounded-lg py-2.5 text-sm font-medium hover:bg-gray-50 transition-colors"
          >
            Quay lại
          </button>
          <button
            onClick={() => navigate(user ? '/tenant/invoices' : '/login', { replace: true })}
            className="flex-1 bg-indigo-600 text-white rounded-lg py-2.5 text-sm font-medium hover:bg-indigo-700 transition-colors"
          >
            Xem hóa đơn
          </button>
        </div>
      </div>
    </div>
  )
}
