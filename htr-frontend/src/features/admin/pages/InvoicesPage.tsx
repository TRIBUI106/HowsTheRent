import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { Pagination } from '@/components/ui/pagination'
import { TableSkeleton } from '@/components/ui/feedback'
import { formatCurrency, formatDate } from '@/lib/utils'
import type { Invoice } from '@/types'
import { Download } from 'lucide-react'

const SIZE = 20

const STATUS_OPTIONS = ['', 'PENDING', 'PAID', 'OVERDUE', 'CANCELLED']

export default function AdminInvoicesPage() {
  const [page, setPage] = useState(0)
  const [statusFilter, setStatusFilter] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['invoices', page, statusFilter],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), size: String(SIZE) })
      if (statusFilter) params.set('status', statusFilter)
      return api.get(`/invoices?${params}`).then(r => r.data)
    },
  })

  const invoices: Invoice[] = Array.isArray(data) ? data : (data?.content ?? [])
  const totalPages: number = Array.isArray(data) ? 1 : (data?.totalPages ?? 1)

  return (
    <Layout title="Hóa đơn">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-fg">Hóa đơn</h1>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={() => {
              api.get('/export/invoices', { responseType: 'blob' })
                .then(r => r.data)
                .then(blob => {
                  const url = URL.createObjectURL(blob)
                  const a = document.createElement('a')
                  a.href = url; a.download = 'hoadon.xlsx'; a.click()
                  URL.revokeObjectURL(url)
                })
            }}>
              <Download size={14} className="mr-1" /> Excel
            </Button>
            <div className="flex gap-2">
              {STATUS_OPTIONS.map(s => (
                <button
                  key={s || 'ALL'}
                  onClick={() => { setStatusFilter(s); setPage(0) }}
                  className={`px-3 py-1.5 rounded-xl text-sm font-medium transition-colors ${
                    statusFilter === s
                      ? 'bg-accent text-accent-fg'
                      : 'bg-sidebar text-fg-muted hover:bg-surface hover:text-fg'
                  }`}
                >
                  {s || 'Tất cả'}
                </button>
              ))}
            </div>
          </div>
        </div>

        {isLoading ? (
          <TableSkeleton rows={6} columns={6} />
        ) : (
          <Card>
            <Table headers={['Tháng', 'Phòng', 'Tổng tiền', 'Trạng thái', 'Hạn', 'Thanh toán']}>
              {invoices.map(inv => (
                <TableRow key={inv.id}>
                  <TableCell>{inv.invoiceMonth?.slice(0, 7)}</TableCell>
                  <TableCell>{inv.room?.roomNumber}</TableCell>
                  <TableCell className="font-medium">{formatCurrency(inv.totalAmount)}</TableCell>
                  <TableCell><Badge status={inv.status} /></TableCell>
                  <TableCell>{formatDate(inv.dueDate)}</TableCell>
                  <TableCell>{inv.paymentMethod || '-'}</TableCell>
                </TableRow>
              ))}
              {invoices.length === 0 && (
                <TableRow>
                  <TableCell className="text-center text-fg-subtle py-8">Không có hóa đơn</TableCell>
                </TableRow>
              )}
            </Table>
            <div className="px-4">
              <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
            </div>
          </Card>
        )}
      </div>
    </Layout>
  )
}
