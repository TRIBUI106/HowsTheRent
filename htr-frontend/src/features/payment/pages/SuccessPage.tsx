import { useEffect } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { Button } from '@/components/ui/button'
import { CheckCircle2 } from 'lucide-react'
import { formatCurrency } from '@/lib/utils'

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
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <div className="bg-surface rounded-2xl shadow-[0_2px_8px_rgba(15,23,42,0.06)] border border-border/80 p-8 max-w-md w-full text-center space-y-4 animate-scale-in">
        <div className="flex items-center justify-center w-16 h-16 mx-auto bg-success-surface rounded-full">
          <CheckCircle2 className="w-8 h-8 text-success" />
        </div>
        <h1 className="text-2xl font-bold text-fg">Thanh toán thành công!</h1>
        <p className="text-fg-muted">
          Hóa đơn của bạn đã được thanh toán.
          {orderCode && <> Mã đơn: <span className="font-medium text-fg">{orderCode}</span></>}
        </p>
        {amount && (
          <p className="text-lg font-semibold text-success">
            {formatCurrency(Number(amount) / 100)}
          </p>
        )}
        <p className="text-sm text-fg-subtle">Tự động chuyển hướng sau 4 giây...</p>
        <Button
          type="button"
          size="lg"
          className="w-full mt-2"
          onClick={() => navigate(user ? '/tenant/invoices' : '/login', { replace: true })}
        >
          Xem hóa đơn
        </Button>
      </div>
    </div>
  )
}
