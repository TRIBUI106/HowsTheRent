import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { Pagination } from '@/components/ui/pagination'
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
      <div className="p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Hóa đơn</h1>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={() => {
              const token = localStorage.getItem('accessToken')
              fetch('/api/export/invoices', { headers: { Authorization: `Bearer ${token}` } })
                .then(r => r.blob())
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
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    statusFilter === s
                      ? 'bg-indigo-600 text-white'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {s || 'Tất cả'}
                </button>
              ))}
            </div>
          </div>
        </div>

        {isLoading ? (
          <div className="flex h-32 items-center justify-center">
            <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
          </div>
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
                  <TableCell className="text-center text-gray-400 py-8">Không có hóa đơn</TableCell>
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