import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { EmptyState } from '@/components/ui/feedback'
import { formatCurrency } from '@/lib/utils'
import type { Dashboard } from '@/types'
import {
  Building2, Home, DoorOpen, TrendingUp, BadgeDollarSign,
  AlertCircle, Wrench, Clock,
} from 'lucide-react'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'

interface RevenueEntry {
  month: string
  label: string
  amount: number
}

const summaryCards = [
  { label: 'Doanh thu tháng', key: 'revenueThisMonth', icon: BadgeDollarSign, tone: 'success', format: 'currency' },
  { label: 'Hóa đơn quá hạn', key: 'overdueInvoices', icon: AlertCircle, tone: 'error' },
  { label: 'Bảo trì mới', key: 'openMaintenance', icon: Wrench, tone: 'warning' },
  { label: 'Đang xử lý', key: 'inProgressMaintenance', icon: Clock, tone: 'accent' },
] satisfies Array<{
  label: string
  key: keyof Dashboard
  icon: typeof BadgeDollarSign
  tone: string
  format?: 'currency'
}>

const inventoryCards = [
  { label: 'Tổng tài sản', key: 'totalProperties', icon: Building2 },
  { label: 'Tổng phòng', key: 'totalRooms', icon: Home },
  { label: 'Phòng trống', key: 'emptyRooms', icon: DoorOpen },
  { label: 'Tỷ lệ lấp đầy', key: 'occupancyRate', icon: TrendingUp, suffix: '%' },
] satisfies Array<{
  label: string
  key: keyof Dashboard
  icon: typeof Building2
  suffix?: string
}>

function DashboardSkeleton() {
  return (
    <div className="space-y-5">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="rounded-2xl border border-border/80 bg-surface p-5">
            <div className="h-3 w-24 rounded bg-sidebar animate-pulse" />
            <div className="mt-4 h-8 w-32 rounded bg-sidebar animate-pulse" />
            <div className="mt-5 h-9 w-9 rounded-xl bg-sidebar animate-pulse" />
          </div>
        ))}
      </div>
      <div className="grid grid-cols-1 gap-5 xl:grid-cols-[1.2fr_0.8fr]">
        <div className="rounded-2xl border border-border/80 bg-surface p-5 h-80 animate-pulse" />
        <div className="rounded-2xl border border-border/80 bg-surface p-5 h-80 animate-pulse" />
      </div>
    </div>
  )
}

function toneClasses(tone: string) {
  switch (tone) {
    case 'success':
      return 'bg-success-surface text-success-fg'
    case 'error':
      return 'bg-error-surface text-error-fg'
    case 'warning':
      return 'bg-warning-surface text-warning-fg'
    default:
      return 'bg-accent-surface text-accent'
  }
}

export default function AdminDashboard() {
  const { data, isLoading } = useQuery<Dashboard>({
    queryKey: ['dashboard'],
    queryFn: () => api.get('/dashboard').then(r => r.data),
  })

  const [chartMonths, setChartMonths] = useState(6)
  const { data: revenueData = [] } = useQuery<RevenueEntry[]>({
    queryKey: ['monthly-revenue', chartMonths],
    queryFn: () => api.get(`/dashboard/revenue?months=${chartMonths}`).then(r => r.data),
  })

  const chartData = useMemo(() => revenueData.map((r) => ({
    ...r,
    amount: Number(r.amount) / 1_000_000,
  })), [revenueData])

  const occupancyData = [
    { label: 'Đang thuê', value: Number((data?.occupancyRate ?? 0).toFixed(1)) },
    { label: 'Phòng trống', value: Number((100 - (data?.occupancyRate ?? 0)).toFixed(1)) },
  ]

  if (isLoading) {
    return (
      <Layout title="Tổng quan">
        <DashboardSkeleton />
      </Layout>
    )
  }

  return (
    <Layout title="Tổng quan">
      <section className="mb-5 flex flex-col gap-4 rounded-[28px] border border-border/80 bg-surface px-6 py-6 lg:flex-row lg:items-end lg:justify-between">
        <div className="max-w-2xl">
          <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-fg-subtle">Tình hình hôm nay</p>
          <h2 className="mt-2 text-[28px] font-semibold tracking-[-0.02em] text-fg">Nắm nhanh việc cần xử lý trước khi bắt đầu ngày làm việc.</h2>
          <p className="mt-2 text-sm leading-6 text-fg-muted">
            Tập trung vào công nợ, yêu cầu bảo trì và tỷ lệ lấp đầy để biết khu vực nào cần can thiệp ngay.
          </p>
        </div>
        <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4 lg:w-[480px]">
          {inventoryCards.map(card => {
            const Icon = card.icon
            const rawValue = data?.[card.key] ?? 0
            const value = card.suffix
              ? `${Number(rawValue).toFixed(1)}${card.suffix}`
              : rawValue
            return (
              <div key={card.key} className="rounded-2xl border border-border/70 bg-bg px-4 py-3">
                <div className="flex items-center justify-between gap-3">
                  <p className="text-xs text-fg-muted">{card.label}</p>
                  <Icon size={14} className="text-fg-subtle" />
                </div>
                <p className="mt-3 text-xl font-semibold tracking-[-0.02em] text-fg">{value}</p>
              </div>
            )
          })}
        </div>
      </section>

      <section className="mb-5 grid grid-cols-1 gap-4 xl:grid-cols-4">
        {summaryCards.map(card => {
          const Icon = card.icon
          const rawValue = data?.[card.key] ?? 0
          const value = card.format === 'currency' ? formatCurrency(Number(rawValue)) : rawValue
          return (
            <Card key={card.key} className="overflow-hidden">
              <CardContent className="p-5">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <p className="text-sm text-fg-muted">{card.label}</p>
                    <p className="mt-3 text-[28px] font-semibold tracking-[-0.03em] text-fg">{value}</p>
                  </div>
                  <div className={`inline-flex h-11 w-11 items-center justify-center rounded-2xl ${toneClasses(card.tone)}`}>
                    <Icon size={18} />
                  </div>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </section>

      <section className="grid grid-cols-1 gap-5 xl:grid-cols-[1.2fr_0.8fr]">
        <Card>
          <CardHeader className="flex flex-col gap-4 border-b border-border/80 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-fg-subtle">Doanh thu</p>
              <h3 className="mt-1 text-lg font-semibold tracking-[-0.01em] text-fg">Dòng tiền theo tháng</h3>
              <p className="mt-1 text-sm text-fg-muted">Theo dõi xu hướng thu tiền trong các kỳ gần nhất.</p>
            </div>
            <div className="flex gap-1.5 rounded-xl bg-sidebar p-1">
              {[3, 6, 12].map(m => (
                <button
                  key={m}
                  onClick={() => setChartMonths(m)}
                  className={`rounded-lg px-3 py-1.5 text-xs font-medium transition-colors ${
                    chartMonths === m ? 'bg-surface text-fg shadow-sm' : 'text-fg-muted hover:text-fg'
                  }`}
                >
                  {m} tháng
                </button>
              ))}
            </div>
          </CardHeader>
          <CardContent className="pt-5">
            {chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height={280}>
                <BarChart data={chartData} margin={{ top: 6, right: 8, left: -12, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" vertical={false} />
                  <XAxis dataKey="label" tick={{ fontSize: 11, fill: 'var(--color-fg-subtle)' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: 'var(--color-fg-subtle)' }} tickFormatter={(v) => `${v} tr`} axisLine={false} tickLine={false} />
                  <Tooltip
                    cursor={{ fill: 'var(--color-accent-surface)' }}
                    formatter={(v) => [`${Number(v).toFixed(1)} triệu`, 'Doanh thu']}
                    contentStyle={{ borderRadius: 16, border: '1px solid var(--color-border)', background: 'var(--color-surface)' }}
                  />
                  <Bar dataKey="amount" fill="var(--color-accent)" radius={[8, 8, 0, 0]} name="Doanh thu" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <EmptyState message="Chưa có dữ liệu doanh thu cho khoảng thời gian này." />
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-fg-subtle">Công suất</p>
            <h3 className="mt-1 text-lg font-semibold tracking-[-0.01em] text-fg">Tỷ lệ lấp đầy hiện tại</h3>
            <p className="mt-1 text-sm text-fg-muted">So sánh nhanh giữa số phòng đang thuê và số phòng còn trống.</p>
          </CardHeader>
          <CardContent className="pt-5">
            <div className="mb-5 flex items-end justify-between gap-3">
              <div>
                <p className="text-sm text-fg-muted">Đang khai thác</p>
                <p className="mt-1 text-[32px] font-semibold tracking-[-0.03em] text-fg">{(data?.occupancyRate ?? 0).toFixed(1)}%</p>
              </div>
              <div className="rounded-2xl bg-accent-surface px-3 py-2 text-right">
                <p className="text-xs text-accent">Phòng trống</p>
                <p className="mt-1 text-sm font-semibold text-accent">{data?.emptyRooms ?? 0} phòng</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={occupancyData} margin={{ top: 6, right: 8, left: -12, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" vertical={false} />
                <XAxis dataKey="label" tick={{ fontSize: 11, fill: 'var(--color-fg-subtle)' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: 'var(--color-fg-subtle)' }} tickFormatter={(v) => `${v}%`} axisLine={false} tickLine={false} />
                <Tooltip
                  cursor={{ fill: 'var(--color-accent-surface)' }}
                  formatter={(v) => [`${Number(v)}%`, 'Tỷ lệ']}
                  contentStyle={{ borderRadius: 16, border: '1px solid var(--color-border)', background: 'var(--color-surface)' }}
                />
                <Bar dataKey="value" fill="var(--color-success)" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </section>
    </Layout>
  )
}
