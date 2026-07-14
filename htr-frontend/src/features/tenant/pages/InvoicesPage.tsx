import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import { invoiceApi } from '@/api/invoiceApi'
import { extractPageContent, normalizeInvoice } from '@/lib/apiMappers'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { TableSkeleton } from '@/components/ui/feedback'
import { Dialog } from '@/components/ui/dialog'
import { Banknote, QrCode } from 'lucide-react'
import { showToast } from '@/lib/toast'
import { formatCurrency, formatDate, formatMonth } from '@/lib/utils'
import type { Invoice } from '@/types'

export default function TenantInvoicesPage() {
  const qc = useQueryClient()
  const [paymentInvoice, setPaymentInvoice] = useState<Invoice | null>(null)
  const { data, isLoading } = useQuery({
    queryKey: ['tenant-invoices'],
    queryFn: () => api.get('/invoices/mine').then(r => r.data),
  })

  const invoices: Invoice[] = extractPageContent<any>(data).map(normalizeInvoice)

  async function handleOnlinePay(invoice: Invoice) {
    if (invoice.checkoutUrl) {
      window.open(invoice.checkoutUrl, '_blank')
    } else {
      const { data: payment } = await api.post(`/invoices/${invoice.id}/pay-online`)
      window.open(payment.checkoutUrl, '_blank')
    }
  }

  const cashMutation = useMutation({
    mutationFn: (id: string) => invoiceApi.requestCashPayment(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tenant-invoices'] })
      setPaymentInvoice(null)
      showToast({ message: 'Đã đăng ký thanh toán tiền mặt. Vui lòng thanh toán với quản lý.', type: 'success' })
    },
    onError: (error: any) => showToast({ message: error?.response?.data?.message ?? 'Không thể đăng ký thanh toán tiền mặt', type: 'error' }),
  })

  return (
    <Layout title="Hóa đơn">
      {isLoading ? (
        <TableSkeleton rows={5} columns={6} />
      ) : (
        <Card>
          <Table headers={['Tháng', 'Phòng', 'Tổng tiền', 'Trạng thái', 'Hạn', 'Thao tác']}>
            {invoices.map(inv => (
              <TableRow key={inv.id}>
                <TableCell>{formatMonth(inv.invoiceMonth)}</TableCell>
                <TableCell>{inv.room?.roomNumber}</TableCell>
                <TableCell className="font-medium">{formatCurrency(inv.totalAmount)}</TableCell>
                <TableCell><Badge status={inv.status} /></TableCell>
                <TableCell>{formatDate(inv.dueDate)}</TableCell>
                <TableCell>
                  {inv.status === 'PENDING' && (
                    <Button size="sm" onClick={() => setPaymentInvoice(inv)}>Thanh toán</Button>
                  )}
                  {inv.status === 'PAID' && <span className="text-sm text-success">Đã thanh toán</span>}
                </TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}
      <Dialog open={!!paymentInvoice} onClose={() => setPaymentInvoice(null)} title="Chọn phương thức thanh toán">
        {paymentInvoice && (
          <div className="grid gap-3 sm:grid-cols-2">
            <button
              className="rounded-xl border border-border p-4 text-left transition-colors hover:border-accent hover:bg-accent/5"
              onClick={() => handleOnlinePay(paymentInvoice)}
            >
              <QrCode className="mb-3 text-accent" size={24} />
              <p className="font-semibold text-fg">QR / PayOS</p>
              <p className="mt-1 text-xs text-fg-muted">Mở cổng thanh toán trực tuyến.</p>
            </button>
            <button
              className="rounded-xl border border-border p-4 text-left transition-colors hover:border-accent hover:bg-accent/5 disabled:opacity-50"
              disabled={cashMutation.isPending}
              onClick={() => cashMutation.mutate(paymentInvoice.id)}
            >
              <Banknote className="mb-3 text-success" size={24} />
              <p className="font-semibold text-fg">Tiền mặt</p>
              <p className="mt-1 text-xs text-fg-muted">Đăng ký và thanh toán trực tiếp với quản lý.</p>
            </button>
          </div>
        )}
      </Dialog>
    </Layout>
  )
}
