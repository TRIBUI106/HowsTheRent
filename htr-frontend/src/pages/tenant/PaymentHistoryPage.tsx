import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatDate, formatCurrency } from '@/lib/utils'

export default function PaymentHistoryPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['tenant-invoices'],
    queryFn: () => api.get('/invoices/mine').then(r => r.data),
  })

  const invoices = Array.isArray(data) ? data : (data?.content ?? [])
  const paid = invoices
    .filter((i: any) => i.status === 'PAID')
    .sort((a: any, b: any) => new Date(b.paidAt ?? b.invoiceMonth).getTime() - new Date(a.paidAt ?? a.invoiceMonth).getTime())

  return (
    <Layout title="Lịch sử thanh toán">
      <div className="p-6">
        {isLoading ? (
          <div className="flex h-48 items-center justify-center">
            <div className="animate-spin h-6 w-6 border-2 border-indigo-600 border-t-transparent rounded-full" />
          </div>
        ) : paid.length === 0 ? (
          <div className="text-center py-12 text-gray-400">Chưa có lịch sử thanh toán</div>
        ) : (
          <div className="space-y-3">
            {paid.map((inv: any) => (
              <Card key={inv.id}>
                <CardContent className="p-4 flex items-center justify-between">
                  <div>
                    <p className="font-medium text-gray-900">
                      Tháng {new Date(inv.invoiceMonth).toLocaleDateString('vi-VN', { month: 'long', year: 'numeric' })}
                    </p>
                    <p className="text-sm text-gray-500 mt-0.5">
                      {inv.paymentMethod === 'CASH' ? 'Tiền mặt' : 'PayOS'} •{' '}
                      {inv.paidAt ? formatDate(inv.paidAt) : '—'}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-green-600">{formatCurrency(inv.totalAmount)}</p>
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