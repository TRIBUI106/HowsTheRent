import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import { extractPageContent, normalizeInvoice } from '@/lib/apiMappers'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate, formatCurrency, formatMonth } from '@/lib/utils'
import type { Invoice } from '@/types'

export default function PaymentHistoryPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['tenant-invoices'],
    queryFn: () => api.get('/invoices/mine').then(r => r.data),
  })

  const invoices: Invoice[] = extractPageContent<any>(data).map(normalizeInvoice)
  const paid = invoices
    .filter(i => i.status === 'PAID')
    .sort((a, b) => new Date(b.paidAt ?? b.invoiceMonth).getTime() - new Date(a.paidAt ?? a.invoiceMonth).getTime())

  return (
    <Layout title="Lịch sử thanh toán">
      <div>
        {isLoading ? (
          <ListSkeleton items={4} />
        ) : paid.length === 0 ? (
          <div className="py-12 text-center text-fg-subtle">Chưa có lịch sử thanh toán</div>
        ) : (
          <div className="space-y-3">
            {paid.map(inv => (
              <Card key={inv.id}>
                <CardContent className="flex items-center justify-between p-4">
                  <div>
                    <p className="font-medium text-fg">
                      Tháng {formatMonth(inv.invoiceMonth)}
                    </p>
                    <p className="mt-0.5 text-sm text-fg-muted">
                      {inv.paymentMethod === 'CASH' ? 'Tiền mặt' : 'PayOS'} ·{' '}
                      {inv.paidAt ? formatDate(inv.paidAt) : '-'}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-success">{formatCurrency(inv.totalAmount)}</p>
                    <Badge status="PAID" />
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </Layout>
  )
}
