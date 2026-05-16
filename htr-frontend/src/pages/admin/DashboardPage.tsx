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
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts'
import { useState } from 'react'

interface RevenueEntry { month: string; label: string; amount: number }

function SkeletonCard() {
  return (
    <Card><CardContent className="p-5">
      <div className="flex items-center justify-between mb-3">
        <div className="h-3 w-24 bg-gray-200 rounded animate-pulse" />
        <div className="h-9 w-9 bg-gray-200 rounded-lg animate-pulse" />
      </div>
      <div className="h-8 w-20 bg-gray-200 rounded animate-pulse" />
    </CardContent></Card>
  )
}

const cards = [
  { label: 'Tổng tài sản',     key: 'totalProperties',    icon: Building2,        color: 'text-indigo-600', bg: 'bg-indigo-50' },
  { label: 'Tổng phòng',       key: 'totalRooms',         icon: Home,             color: 'text-blue-600',   bg: 'bg-blue-50' },
  { label: 'Phòng trống',      key: 'emptyRooms',         icon: DoorOpen,         color: 'text-amber-600',  bg: 'bg-amber-50' },
  { label: 'Tỷ lệ lấp đầy',   key: 'occupancyRate',      icon: TrendingUp,       color: 'text-green-600',  bg: 'bg-green-50', suffix: '%' },
  { label: 'Doanh thu tháng',  key: 'revenueThisMonth',   icon: BadgeDollarSign,  color: 'text-emerald-600',bg: 'bg-emerald-50', isCurrency: true },
  { label: 'Hóa đơn quá hạn',  key: 'overdueInvoices',    icon: AlertCircle,      color: 'text-red-600',    bg: 'bg-red-50' },
  { label: 'Bảo trì mới',     key: 'openMaintenance',     icon: Wrench,           color: 'text-orange-600', bg: 'bg-orange-50' },
  { label: 'Đang xử lý',      key: 'inProgressMaintenance',icon: Clock,           color: 'text-sky-600',    bg: 'bg-sky-50' },
]

export default function AdminDashboard() {
  const { data, isLoading } = useQuery<Dashboard>({
    queryKey: ['dashboard'],
    queryFn: () => api.get('/dashboard').then(r => r.data),
  })

  const [chartMonths, setChartMonths] = useState(6)
  const { data: revenueData2 } = useQuery<RevenueEntry[]>({
    queryKey: ['monthly-revenue', chartMonths],
    queryFn: () => api.get(`/dashboard/revenue?months=${chartMonths}`).then(r => r.data),
    enabled: false,
  })

  const chartData = revenueData2?.map((r: RevenueEntry) => ({
    ...r,
    amount: Number(r.amount) / 1_000_000,
  })) ?? []

  return (
    <Layout title="Tổng quan">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-6">
        {isLoading
          ? Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)
          : cards.map(card => {
              const Icon = card.icon
              let value = (data as any)?.[card.key] ?? 0
              if (card.isCurrency) value = formatCurrency(value)
              else if (card.suffix) value = `${(value as number).toFixed(1)}${card.suffix}`
              return (
                <Card key={card.key} className="hover:shadow-md transition-shadow duration-200">
                  <CardContent className="p-5">
                    <div className="flex items-center justify-between mb-3">
                      <p className="text-sm font-medium text-gray-500">{card.label}</p>
                      <div className={`${card.bg} p-2 rounded-lg`}><Icon size={18} className={card.color} /></div>
                    </div>
                    <p className={`text-2xl font-bold ${card.color}`}>{value}</p>
                  </CardContent>
                </Card>
              )
            })
        }
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold text-gray-900">Doanh thu theo tháng</h3>
              <div className="flex gap-2">
                {[3, 6, 12].map(m => (
                  <button key={m} onClick={() => setChartMonths(m)}
                    className={`px-3 py-1 rounded text-xs font-medium ${chartMonths === m ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600'}`}>
                    {m} tháng
                  </button>
                ))}
              </div>
            </div>
            {chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={chartData} margin={{ top: 5, right: 10, left: -10, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="label" tick={{ fontSize: 11 }} />
                  <YAxis tick={{ fontSize: 11 }} tickFormatter={v => `${v} tr`} />
                  <Tooltip formatter={(v: any) => [`${Number(v).toFixed(1)} triệu`, 'Doanh thu']} />
                  <Bar dataKey="amount" fill="#6366f1" radius={[4, 4, 0, 0]} name="Doanh thu" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex h-48 items-center justify-center text-gray-400 text-sm">Chưa có dữ liệu doanh thu</div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-5">
            <h3 className="font-semibold text-gray-900 mb-4">Tỷ lệ lấp đầy</h3>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={[
                { label: 'Đang thuê', value: (data?.occupancyRate ?? 0).toFixed(1) },
                { label: 'Phòng trống', value: (100 - (data?.occupancyRate ?? 0)).toFixed(1) },
              ]} margin={{ top: 5, right: 10, left: -10, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="label" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} tickFormatter={v => `${v}%`} />
                <Tooltip formatter={(v: any) => [`${v}%`]} />
                <Bar dataKey="value" fill="#10b981" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}