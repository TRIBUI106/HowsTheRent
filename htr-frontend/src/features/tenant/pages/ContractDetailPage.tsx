import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import { extractPageContent, normalizeContract } from '@/lib/apiMappers'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { DetailSkeleton } from '@/components/ui/feedback'
import { formatDate, formatCurrency } from '@/lib/utils'

export default function ContractDetailPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['tenant-contracts'],
    queryFn: () => api.get('/contracts/mine').then(r => r.data),
  })

  const contract = extractPageContent<any>(data).map(normalizeContract)[0]

  if (isLoading) {
    return (
      <Layout title="Hop dong cua toi">
        <DetailSkeleton />
      </Layout>
    )
  }

  if (!contract) {
    return (
      <Layout title="Hop dong cua toi">
        <div className="py-12 text-center text-fg-subtle">Khong co hop dong dang active</div>
      </Layout>
    )
  }

  return (
    <Layout title="Hop dong cua toi">
      <div className="max-w-2xl">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <span>Hop dong thue phong</span>
            <Badge status={contract.status} />
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="mb-1 text-xs text-fg-muted">Phong</p>
                <p className="font-medium text-fg">{contract.room.roomNumber || '-'}</p>
              </div>
              <div>
                <p className="mb-1 text-xs text-fg-muted">Toa nha</p>
                <p className="font-medium text-fg">{contract.room.propertyName || '-'}</p>
              </div>
              <div>
                <p className="mb-1 text-xs text-fg-muted">Ngay vao</p>
                <p className="font-medium text-fg">{contract.moveInDate ? formatDate(contract.moveInDate) : '-'}</p>
              </div>
              <div>
                <p className="mb-1 text-xs text-fg-muted">Ngay ket thuc</p>
                <p className="font-medium text-fg">{contract.moveOutDate ? formatDate(contract.moveOutDate) : 'Khong xac dinh'}</p>
              </div>
              <div>
                <p className="mb-1 text-xs text-fg-muted">Tien coc</p>
                <p className="font-medium text-fg">{formatCurrency(contract.depositAmount ?? 0)}</p>
              </div>
            </div>
            {contract.notes && (
              <div>
                <p className="mb-1 text-xs text-fg-muted">Ghi chu</p>
                <p className="text-sm text-fg-muted">{contract.notes}</p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}
