import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { XCircle } from 'lucide-react'

export default function PaymentCancelPage() {
  const navigate = useNavigate()
  const { user } = useAuthStore()

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <div className="bg-surface rounded-2xl shadow-[0_2px_8px_rgba(15,23,42,0.06)] border border-border/80 p-8 max-w-md w-full text-center space-y-4 animate-scale-in">
        <div className="flex items-center justify-center w-16 h-16 mx-auto bg-warning-surface rounded-full">
          <XCircle className="w-8 h-8 text-warning" />
        </div>
        <h1 className="text-2xl font-bold text-fg">Thanh toán bị hủy</h1>
        <p className="text-fg-muted">
          Bạn đã hủy giao dịch. Hóa đơn vẫn chưa được thanh toán.
        </p>
        <div className="flex gap-3 pt-2">
          <button
            onClick={() => navigate(-1)}
            className="flex-1 border border-border/80 text-fg rounded-xl py-2.5 text-sm font-medium hover:bg-sidebar transition-colors"
          >
            Quay lại
          </button>
          <button
            onClick={() => navigate(user ? '/tenant/invoices' : '/login', { replace: true })}
            className="flex-1 bg-accent text-accent-fg rounded-xl py-2.5 text-sm font-medium hover:bg-accent-hover transition-colors"
          >
            Xem hóa đơn
          </button>
        </div>
      </div>
    </div>
  )
}
