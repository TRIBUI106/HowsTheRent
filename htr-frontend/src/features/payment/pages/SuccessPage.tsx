import { useEffect } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'

export default function PaymentSuccessPage() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const { user } = useAuthStore()

  const orderCode = params.get('orderCode')
  const amount = params.get('amount')

  useEffect(() => {
    const timer = setTimeout(() => {
      navigate(user ? '/tenant/invoices' : '/login', { replace: true })
    }, 4000)
    return () => clearTimeout(timer)
  }, [navigate, user])

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-lg p-8 max-w-md w-full text-center space-y-4">
        <div className="flex items-center justify-center w-16 h-16 mx-auto bg-green-100 rounded-full">
          <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-gray-900">Thanh toán thành công!</h1>
        <p className="text-gray-500">
          Hóa đơn của bạn đã được thanh toán.
          {orderCode && <> Mã đơn: <span className="font-medium text-gray-700">{orderCode}</span></>}
        </p>
        {amount && (
          <p className="text-lg font-semibold text-green-600">
            {(Number(amount) / 100).toLocaleString('vi-VN')} ₫
          </p>
        )}
        <p className="text-sm text-gray-400">Tự động chuyển hướng sau 4 giây…</p>
        <button
          onClick={() => navigate(user ? '/tenant/invoices' : '/login', { replace: true })}
          className="w-full mt-2 bg-indigo-600 text-white rounded-lg py-2.5 text-sm font-medium hover:bg-indigo-700 transition-colors"
        >
          Xem hóa đơn
        </button>
      </div>
    </div>
  )
}
