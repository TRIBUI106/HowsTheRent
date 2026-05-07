import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { Invoice, MaintenanceRequest } from '@/types'

export default function TenantDashboard() {
  const { data: invoices } = useQuery<Invoice[]>({
    queryKey: ['tenant-invoices'],
    queryFn: () => api.get('/invoices/mine').then(r => r.data),
  })

  const { data: maintenance } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tenant-maintenance'],
    queryFn: () => api.get('/maintenance/mine').then(r => r.data),
  })

  const pending = invoices?.filter(i => i.status === 'PENDING') ?? []
  const overdue = invoices?.filter(i => i.status === 'OVERDUE') ?? []

  return (
    <Layout title="Dashboard">
      <div className="space-y-6">
        <div>
          <h3 className="text-lg font-medium text-gray-900 mb-4">Hóa đơn</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card><CardContent className="p-6">
              <p className="text-sm text-gray-500">Tổng hóa đơn</p>
              <p className="text-2xl font-bold">{invoices?.length ?? 0}</p>
            </CardContent></Card>
            <Card><CardContent className="p-6">
              <p className="text-sm text-gray-500">Chờ thanh toán</p>
              <p className="text-2xl font-bold text-orange-600">{pending.length}</p>
            </CardContent></Card>
            <Card><CardContent className="p-6">
              <p className="text-sm text-gray-500">Quá hạn</p>
              <p className="text-2xl font-bold text-red-600">{overdue.length}</p>
            </CardContent></Card>
          </div>
        </div>

        <div>
          <h3 className="text-lg font-medium text-gray-900 mb-4">Yêu cầu bảo trì</h3>
          <Card>
            <div className="divide-y">
              {maintenance?.map(req => (
                <div key={req.id} className="p-4 flex justify-between items-center">
                  <div>
                    <p className="font-medium">{req.title}</p>
                    <p className="text-sm text-gray-500">{req.room?.roomNumber}</p>
                  </div>
                  <Badge status={req.status} />
                </div>
              ))}
              {maintenance?.length === 0 && <p className="p-4 text-center text-gray-400">Chưa có yêu cầu bảo trì</p>}
            </div>
          </Card>
        </div>
      </div>
    </Layout>
  )
}