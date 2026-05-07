import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatDate } from '@/lib/utils'
import type { MaintenanceRequest } from '@/types'

export default function TenantMaintenancePage() {
  const { data: requests, isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tenant-maintenance'],
    queryFn: () => api.get('/maintenance/mine').then(r => r.data),
  })

  return (
    <Layout title="Bảo trì">
      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
        </div>
      ) : (
        <div className="space-y-4">
          {requests?.map(req => (
            <Card key={req.id}>
              <div className="p-4">
                <div className="flex justify-between items-start">
                  <div>
                    <p className="font-medium text-gray-900">{req.title}</p>
                    <p className="text-sm text-gray-500 mt-1">{req.room?.roomNumber}</p>
                    {req.description && <p className="text-sm text-gray-600 mt-2">{req.description}</p>}
                  </div>
                  <Badge status={req.status} />
                </div>
                <p className="text-xs text-gray-400 mt-3">Ngày tạo: {formatDate(req.createdAt)}</p>
              </div>
            </Card>
          ))}
          {requests?.length === 0 && <p className="text-center text-gray-400 py-8">Chưa có yêu cầu bảo trì</p>}
        </div>
      )}
    </Layout>
  )
}