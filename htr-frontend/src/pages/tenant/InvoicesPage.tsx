import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { formatCurrency, formatDate } from '@/lib/utils'
import type { Invoice } from '@/types'

export default function TenantInvoicesPage() {
  const { data: invoices, isLoading } = useQuery<Invoice[]>({
    queryKey: ['tenant-invoices'],
    queryFn: () => api.get('/invoices/mine').then(r => r.data),
  })

  async function handlePay(invoice: Invoice) {
    if (invoice.checkoutUrl) {
      window.open(invoice.checkoutUrl, '_blank')
    } else {
      const { data } = await api.post(`/invoices/${invoice.id}/pay-online`)
      window.open(data.checkoutUrl, '_blank')
    }
  }

  return (
    <Layout title="Hóa đơn">
      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
        </div>
      ) : (
        <Card>
          <Table headers={['Tháng', 'Phòng', 'Tổng tiền', 'Trạng thái', 'Hạn', 'Thao tác']}>
            {invoices?.map(inv => (
              <TableRow key={inv.id}>
                <TableCell>{inv.invoiceMonth?.slice(0, 7)}</TableCell>
                <TableCell>{inv.room?.roomNumber}</TableCell>
                <TableCell className="font-medium">{formatCurrency(inv.totalAmount)}</TableCell>
                <TableCell><Badge status={inv.status} /></TableCell>
                <TableCell>{formatDate(inv.dueDate)}</TableCell>
                <TableCell>
                  {inv.status === 'PENDING' && (
                    <Button size="sm" onClick={() => handlePay(inv)}>Thanh toán</Button>
                  )}
                  {inv.status === 'PAID' && <span className="text-sm text-green-600">Đã thanh toán</span>}
                </TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}
    </Layout>
  )
}