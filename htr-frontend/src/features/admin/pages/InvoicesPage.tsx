import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Dialog } from '@/components/ui/dialog'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { Pagination } from '@/components/ui/pagination'
import { TableSkeleton } from '@/components/ui/feedback'
import { formatCurrency, formatDate, formatMonth } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { Invoice } from '@/types'
import { Download, ReceiptText } from 'lucide-react'

const SIZE = 20

const STATUS_OPTIONS = ['', 'PENDING', 'PAID', 'OVERDUE', 'CANCELLED']

interface InvoiceGenerationResult {
  month: string
  activeContracts: number
  generated: number
  alreadyExists: number
  missingMeterReading: number
  missingFeeConfig: number
  failed: number
  message: string
  details: string[]
}

function currentYearMonth() {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

export default function AdminInvoicesPage() {
  const qc = useQueryClient()
  const [page, setPage] = useState(0)
  const [statusFilter, setStatusFilter] = useState('')
  const [showGenerateDialog, setShowGenerateDialog] = useState(false)
  const [generateMonth, setGenerateMonth] = useState(currentYearMonth())
  const [generateConfirmed, setGenerateConfirmed] = useState(false)
  const [generationResult, setGenerationResult] = useState<InvoiceGenerationResult | null>(null)

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
  const generateMonthLabel = generateMonth ? formatMonth(`${generateMonth}-01`) : ''

  const generateMutation = useMutation({
    mutationFn: async () => {
      const [year, month] = generateMonth.split('-').map(Number)
      const { data } = await api.post('/invoices/generate', null, { params: { year, month } })
      return data as InvoiceGenerationResult
    },
    onSuccess: (data) => {
      setGenerationResult(data)
      showToast({ message: data.message, type: data.generated > 0 ? 'success' : 'info' })
      qc.invalidateQueries({ queryKey: ['invoices'] })
      qc.invalidateQueries({ queryKey: ['tenant-invoices'] })
      setPage(0)
      setStatusFilter('')
      setGenerateConfirmed(false)
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? error?.message ?? 'Không thể tạo hóa đơn',
        type: 'error',
      })
    },
  })

  function openGenerateDialog() {
    setGenerateMonth(currentYearMonth())
    setGenerateConfirmed(false)
    setGenerationResult(null)
    setShowGenerateDialog(true)
  }

  return (
    <Layout title="Hóa đơn">
      <div className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h1 className="text-2xl font-bold text-fg">Hóa đơn</h1>
          <div className="flex flex-wrap items-center justify-end gap-2">
            <Button size="sm" onClick={openGenerateDialog}>
              <ReceiptText size={14} />
              Tạo hóa đơn
            </Button>
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
                  <TableCell>{formatMonth(inv.invoiceMonth)}</TableCell>
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

      <Dialog
        open={showGenerateDialog}
        onClose={() => {
          if (!generateMutation.isPending) setShowGenerateDialog(false)
        }}
        title="Tạo hóa đơn"
      >
        <form
          className="space-y-5"
          onSubmit={(e) => {
            e.preventDefault()
            generateMutation.mutate()
          }}
        >
          <div className="space-y-2">
            <label htmlFor="invoice-month" className="block text-sm font-medium text-fg">
              Tháng lập hóa đơn
            </label>
            <input
              id="invoice-month"
              type="month"
              value={generateMonth}
              onChange={(e) => {
                setGenerateMonth(e.target.value)
                setGenerateConfirmed(false)
                setGenerationResult(null)
              }}
              required
              className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
            />
          </div>

          <div className="rounded-lg border border-warning/30 bg-warning-surface px-4 py-3 text-sm text-fg">
            Hệ thống sẽ tạo hóa đơn cho {generateMonthLabel || 'tháng đã chọn'} với các hợp đồng đang hoạt động.
            Phòng chưa có chỉ số điện nước hoặc đã có hóa đơn tháng này sẽ được bỏ qua.
          </div>

          {generationResult && (
            <div className="space-y-3 rounded-lg border border-border bg-sidebar/50 px-4 py-3">
              <div>
                <p className="text-sm font-medium text-fg">{generationResult.message}</p>
                <p className="text-xs text-fg-muted">
                  {generationResult.activeContracts} hợp đồng đang hoạt động được kiểm tra.
                </p>
              </div>
              <div className="grid grid-cols-2 gap-2 text-sm md:grid-cols-3">
                <div className="rounded-lg bg-surface px-3 py-2">
                  <p className="text-xs text-fg-muted">Đã tạo</p>
                  <p className="font-semibold text-success">{generationResult.generated}</p>
                </div>
                <div className="rounded-lg bg-surface px-3 py-2">
                  <p className="text-xs text-fg-muted">Đã tồn tại</p>
                  <p className="font-semibold text-fg">{generationResult.alreadyExists}</p>
                </div>
                <div className="rounded-lg bg-surface px-3 py-2">
                  <p className="text-xs text-fg-muted">Thiếu chỉ số</p>
                  <p className="font-semibold text-warning-fg">{generationResult.missingMeterReading}</p>
                </div>
                <div className="rounded-lg bg-surface px-3 py-2">
                  <p className="text-xs text-fg-muted">Thiếu cấu hình phí</p>
                  <p className="font-semibold text-warning-fg">{generationResult.missingFeeConfig}</p>
                </div>
                <div className="rounded-lg bg-surface px-3 py-2">
                  <p className="text-xs text-fg-muted">Lỗi</p>
                  <p className="font-semibold text-error">{generationResult.failed}</p>
                </div>
              </div>
              {generationResult.details.length > 0 && (
                <div className="max-h-32 overflow-y-auto rounded-lg bg-surface px-3 py-2 text-xs text-fg-muted">
                  {generationResult.details.slice(0, 8).map((detail) => (
                    <p key={detail}>{detail}</p>
                  ))}
                  {generationResult.details.length > 8 && (
                    <p>... và {generationResult.details.length - 8} phòng khác</p>
                  )}
                </div>
              )}
            </div>
          )}

          <label className="flex items-start gap-3 rounded-lg border border-border bg-sidebar/50 px-3 py-3 text-sm text-fg">
            <input
              type="checkbox"
              checked={generateConfirmed}
              onChange={(e) => setGenerateConfirmed(e.target.checked)}
              className="mt-0.5 h-4 w-4 rounded border-border accent-accent"
            />
            <span>Tôi đã kiểm tra chỉ số điện nước của tháng này và muốn tạo hóa đơn.</span>
          </label>

          <div className="flex justify-end gap-2">
            <Button
              type="button"
              variant="secondary"
              onClick={() => setShowGenerateDialog(false)}
              disabled={generateMutation.isPending}
            >
              Hủy
            </Button>
            <Button
              type="submit"
              loading={generateMutation.isPending}
              disabled={!generateMonth || !generateConfirmed}
            >
              Xác nhận tạo
            </Button>
          </div>
        </form>
      </Dialog>
    </Layout>
  )
}
