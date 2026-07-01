import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import { extractPageContent, normalizeInvoice, normalizeMaintenanceRequest } from '@/lib/apiMappers'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { Invoice, MaintenanceRequest } from '@/types'

export default function TenantDashboard() {
  const { data: invoicesData } = useQuery({
    queryKey: ['tenant-invoices'],
    queryFn: () => api.get('/invoices/mine').then(r => r.data),
  })

  const { data: maintenanceData } = useQuery({
    queryKey: ['tenant-maintenance'],
    queryFn: () => api.get('/maintenance/mine').then(r => r.data),
  })

  const invoices: Invoice[] = extractPageContent<any>(invoicesData).map(normalizeInvoice)
  const maintenance: MaintenanceRequest[] = extractPageContent<any>(maintenanceData).map(normalizeMaintenanceRequest)

  const pending = invoices.filter(i => i.status === 'PENDING')
  const overdue = invoices.filter(i => i.status === 'OVERDUE')

  return (
    <Layout title="Dashboard">
      <div className="space-y-6">
        <div>
          <h3 className="mb-4 text-lg font-medium text-fg">Hóa đơn</h3>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <Card><CardContent className="p-6">
              <p className="text-sm text-fg-muted">Tổng hóa đơn</p>
              <p className="text-2xl font-bold text-fg">{invoices.length}</p>
            </CardContent></Card>
            <Card><CardContent className="p-6">
              <p className="text-sm text-fg-muted">Chờ thanh toán</p>
              <p className="text-2xl font-bold text-warning">{pending.length}</p>
            </CardContent></Card>
            <Card><CardContent className="p-6">
              <p className="text-sm text-fg-muted">Quá hạn</p>
              <p className="text-2xl font-bold text-error">{overdue.length}</p>
            </CardContent></Card>
          </div>
        </div>

        <div>
          <h3 className="mb-4 text-lg font-medium text-fg">Yêu cầu bảo trì</h3>
          <Card>
            <div className="divide-y divide-border/60">
              {maintenance.map(req => (
                <div key={req.id} className="flex items-center justify-between p-4">
                  <div>
                    <p className="font-medium text-fg">{req.title}</p>
                    <p className="text-sm text-fg-muted">{req.room?.roomNumber}</p>
                  </div>
                  <Badge status={req.status} />
                </div>
              ))}
              {maintenance.length === 0 && <p className="p-4 text-center text-fg-subtle">Chưa có yêu cầu bảo trì</p>}
            </div>
          </Card>
        </div>
      </div>
    </Layout>
  )
}
