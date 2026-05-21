import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatDate, formatCurrency } from '@/lib/utils'

export default function ContractDetailPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['tenant-invoices'],
    queryFn: () => api.get('/invoices/mine').then(r => r.data),
  })

  // Extract contract info from first invoice
  const invoices = Array.isArray(data) ? data : (data?.content ?? [])
  const firstInvoice = invoices[0]
  const contract = firstInvoice?.contract

  if (isLoading) return (
    <Layout title="Hợp đồng của tôi">
      <div className="flex h-48 items-center justify-center">
        <div className="animate-spin h-6 w-6 border-2 border-indigo-600 border-t-transparent rounded-full" />
      </div>
    </Layout>
  )

  if (!firstInvoice) return (
    <Layout title="Hợp đồng của tôi">
      <div className="p-6 text-center text-gray-400">Không có hợp đồng đang active</div>
    </Layout>
  )

  return (
    <Layout title="Hợp đồng của tôi">
      <div className="p-6 max-w-2xl">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <span>Hợp đồng thuê phòng</span>
            <Badge status={contract?.status ?? 'ACTIVE'} />
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-gray-500 mb-1">Phòng</p>
                <p className="font-medium">{firstInvoice.room?.roomNumber ?? '—'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Tòa nhà</p>
                <p className="font-medium">{firstInvoice.room?.property?.name ?? '—'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Ngày vào</p>
                <p className="font-medium">{contract?.moveInDate ? formatDate(contract.moveInDate) : '—'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Ngày kết thúc</p>
                <p className="font-medium">{contract?.moveOutDate ? formatDate(contract.moveOutDate) : 'Không xác định'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Tiền cọc</p>
                <p className="font-medium">{formatCurrency(contract?.depositAmount ?? 0)}</p>
              </div>
            </div>
            {contract?.notes && (
              <div>
                <p className="text-xs text-gray-500 mb-1">Ghi chú</p>
                <p className="text-sm text-gray-700">{contract.notes}</p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}