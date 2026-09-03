import { useEffect, useRef } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { invoiceApi } from '@/api/invoiceApi'
import { Button } from '@/components/ui/button'
import { CheckCircle2 } from 'lucide-react'
import { formatCurrency } from '@/lib/utils'

export default function PaymentSuccessPage() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const { user } = useAuthStore()

  const orderCode = params.get('orderCode')
  const amount = params.get('amount')
  // Carried through by PayOSService.createPaymentLink specifically so this page can offer the
  // receipt without a separate orderCode → invoice lookup.
  const invoiceId = params.get('invoiceId')

  // Guards against React re-running the effect (StrictMode double-invoke in dev, or a param
  // change) and silently firing a second download for the same visit.
  const hasDownloaded = useRef(false)

  useEffect(() => {
    if (!invoiceId || hasDownloaded.current) return
    hasDownloaded.current = true
    invoiceApi.downloadReceiptPdf(invoiceId)
      .then((blob) => {
        const url = URL.createObjectURL(blob)
        const anchor = document.createElement('a')
        anchor.href = url
        anchor.download = 'bien-lai-thanh-toan.pdf'
        anchor.click()
        URL.revokeObjectURL(url)
      })
      // Silent: the receipt is also always downloadable later from the invoices list, so a
      // failure here (e.g. session not yet rehydrated right after the PayOS redirect) shouldn't
      // interrupt the success flow with an error toast.
      .catch(() => {})
  }, [invoiceId])

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
