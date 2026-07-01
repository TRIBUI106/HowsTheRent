import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import { extractPageContent, normalizeInvoice } from '@/lib/apiMappers'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { TableSkeleton } from '@/components/ui/feedback'
import { formatCurrency, formatDate } from '@/lib/utils'
import type { Invoice } from '@/types'

export default function TenantInvoicesPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['tenant-invoices'],
    queryFn: () => api.get('/invoices/mine').then(r => r.data),
  })

  const invoices: Invoice[] = extractPageContent<any>(data).map(normalizeInvoice)

  async function handlePay(invoice: Invoice) {
    if (invoice.checkoutUrl) {
      window.open(invoice.checkoutUrl, '_blank')
    } else {
      const { data: payment } = await api.post(`/invoices/${invoice.id}/pay-online`)
      window.open(payment.checkoutUrl, '_blank')
    }
  }

  return (
    <Layout title="Hoa don">
      {isLoading ? (
        <TableSkeleton rows={5} columns={6} />
      ) : (
        <Card>
          <Table headers={['Thang', 'Phong', 'Tong tien', 'Trang thai', 'Han', 'Thao tac']}>
            {invoices.map(inv => (
              <TableRow key={inv.id}>
                <TableCell>{inv.invoiceMonth?.slice(0, 7)}</TableCell>
                <TableCell>{inv.room?.roomNumber}</TableCell>
                <TableCell className="font-medium">{formatCurrency(inv.totalAmount)}</TableCell>
                <TableCell><Badge status={inv.status} /></TableCell>
                <TableCell>{formatDate(inv.dueDate)}</TableCell>
                <TableCell>
                  {inv.status === 'PENDING' && (
                    <Button size="sm" onClick={() => handlePay(inv)}>Thanh toan</Button>
                  )}
                  {inv.status === 'PAID' && <span className="text-sm text-success">Da thanh toan</span>}
                </TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}
    </Layout>
  )
}
