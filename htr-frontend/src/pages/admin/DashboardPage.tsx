import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { formatCurrency } from '@/lib/utils'
import type { Dashboard } from '@/types'
import {
  Building2, Home, DoorOpen, TrendingUp, BadgeDollarSign,
  AlertCircle, Wrench, Clock
} from 'lucide-react'

interface StatCard {
  label: string
  value: string | number
  icon: React.ElementType
  color: string
  bg: string
}

function SkeletonCard() {
  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex items-center justify-between mb-3">
          <div className="h-3 w-24 bg-gray-200 rounded animate-pulse" />
          <div className="h-9 w-9 bg-gray-200 rounded-lg animate-pulse" />
        </div>
        <div className="h-8 w-20 bg-gray-200 rounded animate-pulse" />
      </CardContent>
    </Card>
  )
}

export default function AdminDashboard() {
  const { data, isLoading } = useQuery<Dashboard>({
    queryKey: ['dashboard'],
    queryFn: () => api.get('/dashboard').then(r => r.data),
  })

  const cards: StatCard[] = [
    { label: 'Tổng tài sản',     value: data?.totalProperties ?? 0,                          icon: Building2,         color: 'text-indigo-600', bg: 'bg-indigo-50' },
    { label: 'Tổng phòng',       value: data?.totalRooms ?? 0,                               icon: Home,              color: 'text-blue-600',   bg: 'bg-blue-50' },
    { label: 'Phòng trống',      value: data?.emptyRooms ?? 0,                               icon: DoorOpen,          color: 'text-amber-600',  bg: 'bg-amber-50' },
    { label: 'Tỷ lệ lấp đầy',   value: `${(data?.occupancyRate ?? 0).toFixed(1)}%`,          icon: TrendingUp,        color: 'text-green-600',  bg: 'bg-green-50' },
    { label: 'Doanh thu tháng',  value: formatCurrency(data?.revenueThisMonth ?? 0),         icon: BadgeDollarSign,   color: 'text-emerald-600',bg: 'bg-emerald-50' },
    { label: 'Hóa đơn quá hạn', value: data?.overdueInvoices ?? 0,                          icon: AlertCircle,       color: 'text-red-600',    bg: 'bg-red-50' },
    { label: 'Bảo trì mới',     value: data?.openMaintenance ?? 0,                          icon: Wrench,            color: 'text-orange-600', bg: 'bg-orange-50' },
    { label: 'Đang xử lý',      value: data?.inProgressMaintenance ?? 0,                    icon: Clock,             color: 'text-sky-600',    bg: 'bg-sky-50' },
  ]

  return (
    <Layout title="Tổng quan">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {isLoading
          ? Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)
          : cards.map(card => {
              const Icon = card.icon
              return (
                <Card key={card.label} className="hover:shadow-md transition-shadow duration-200">
                  <CardContent className="p-5">
                    <div className="flex items-center justify-between mb-3">
                      <p className="text-sm font-medium text-gray-500">{card.label}</p>
                      <div className={`${card.bg} p-2 rounded-lg`}>
                        <Icon size={18} className={card.color} />
                      </div>
                    </div>
                    <p className={`text-2xl font-bold ${card.color}`}>{card.value}</p>
                  </CardContent>
                </Card>
              )
            })
        }
      </div>
    </Layout>
  )
}
