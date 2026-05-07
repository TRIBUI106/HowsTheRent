import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { formatCurrency } from '@/lib/utils'
import type { Dashboard } from '@/types'

export default function AdminDashboard() {
  const { data, isLoading } = useQuery<Dashboard>({
    queryKey: ['dashboard'],
    queryFn: () => api.get('/dashboard').then(r => r.data),
  })

  const cards = [
    { label: 'Tổng tài sản', value: data?.totalProperties ?? 0, color: 'text-blue-600' },
    { label: 'Tổng phòng', value: data?.totalRooms ?? 0, color: 'text-blue-600' },
    { label: 'Phòng trống', value: data?.emptyRooms ?? 0, color: 'text-orange-600' },
    { label: 'Tỷ lệ lấp đầy', value: `${(data?.occupancyRate ?? 0).toFixed(1)}%`, color: 'text-green-600' },
    { label: 'Doanh thu tháng', value: formatCurrency(data?.revenueThisMonth ?? 0), color: 'text-green-600' },
    { label: 'Hóa đơn quá hạn', value: data?.overdueInvoices ?? 0, color: 'text-red-600' },
    { label: 'Bảo trì mới', value: data?.openMaintenance ?? 0, color: 'text-orange-600' },
    { label: 'Đang xử lý', value: data?.inProgressMaintenance ?? 0, color: 'text-blue-600' },
  ]

  return (
    <Layout title="Dashboard">
      {isLoading ? (
        <div className="flex h-64 items-center justify-center">
          <div className="animate-spin h-8 w-8 border-4 border-blue-600 border-t-transparent rounded-full" />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {cards.map((card) => (
            <Card key={card.label}>
              <CardContent className="p-6">
                <p className="text-sm text-gray-500">{card.label}</p>
                <p className={`text-2xl font-bold mt-1 ${card.color}`}>{card.value}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </Layout>
  )
}