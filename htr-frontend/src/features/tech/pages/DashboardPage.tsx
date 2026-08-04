import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { ClipboardList, Play, CheckCircle2, AlertTriangle, Star } from 'lucide-react'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { CardsSkeleton, ListSkeleton } from '@/components/ui/feedback'
import { Badge } from '@/components/ui/badge'
import { maintenanceApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import { priorityColor, priorityLabel } from '@/lib/utils'
import type { MaintenanceRequest } from '@/types'

export default function TechDashboardPage() {
  const { user } = useAuthStore()

  const { data: requests = [], isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tech-maintenance'],
    queryFn: () => maintenanceApi.listAssigned(),
  })

  const assignedCount = requests.filter(r => r.status === 'ASSIGNED' || r.status === 'OPEN').length
  const inProgressCount = requests.filter(r => r.status === 'IN_PROGRESS').length
  const doneCount = requests.filter(r => r.status === 'COMPLETED' || r.status === 'DONE' || r.status === 'PENDING_REVIEW' || r.status === 'PENDING_PAYMENT').length
  const urgentCount = requests.filter(r => r.priority === 'URGENT' && r.status !== 'DONE' && r.status !== 'COMPLETED' && r.status !== 'CANCELLED').length

  const activeRequests = requests
    .filter(r => r.status === 'ASSIGNED' || r.status === 'OPEN' || r.status === 'IN_PROGRESS')
    .slice(0, 5)

  return (
    <Layout title="Tổng quan">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-fg">Chào, {user?.fullName}</h1>
          <p className="text-sm text-fg-muted">Tổng quan công việc bảo trì được giao cho bạn</p>
        </div>

        {isLoading ? (
          <CardsSkeleton count={4} />
        ) : (
          <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
            <Card>
              <CardContent className="p-5 space-y-1">
                <div className="flex items-center gap-2 text-fg-muted">
                  <ClipboardList size={15} />
                  <p className="text-xs">Chưa xử lý</p>
                </div>
                <p className="text-2xl font-bold text-fg">{assignedCount}</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-5 space-y-1">
                <div className="flex items-center gap-2 text-fg-muted">
                  <Play size={15} />
                  <p className="text-xs">Đang thi công</p>
                </div>
                <p className="text-2xl font-bold text-accent">{inProgressCount}</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-5 space-y-1">
                <div className="flex items-center gap-2 text-fg-muted">
                  <CheckCircle2 size={15} />
                  <p className="text-xs">Đã xong / Nghiệm thu</p>
                </div>
                <p className="text-2xl font-bold text-success">{doneCount}</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-5 space-y-1">
                <div className="flex items-center gap-2 text-fg-muted">
                  <AlertTriangle size={15} />
                  <p className="text-xs">Khẩn cấp</p>
                </div>
                <p className="text-2xl font-bold text-error">{urgentCount}</p>
              </CardContent>
            </Card>
          </div>
        )}

        {user?.avgRating !== undefined && (
          <Card>
            <CardContent className="p-5 flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-100 text-amber-600 dark:bg-amber-950/40 dark:text-amber-400">
                <Star size={18} fill="currentColor" />
              </div>
              <div>
                <p className="text-xs text-fg-muted">Đánh giá trung bình</p>
                <p className="text-lg font-semibold text-fg">{user.avgRating.toFixed(1)} / 5</p>
              </div>
            </CardContent>
          </Card>
        )}

        <div>
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-lg font-medium text-fg">Công việc cần xử lý</h3>
            <Link to="/tech/maintenance" className="text-sm text-accent hover:underline">Xem tất cả</Link>
          </div>
          {isLoading ? (
            <ListSkeleton items={3} />
          ) : activeRequests.length === 0 ? (
            <div className="py-12 text-center text-fg-subtle rounded-2xl border border-dashed border-border">
              Không có công việc nào đang chờ xử lý
            </div>
          ) : (
            <div className="space-y-3">
              {activeRequests.map(req => (
                <Link key={req.id} to="/tech/maintenance">
                  <Card className="hover:border-border transition-colors">
                    <CardContent className="p-4 flex items-center justify-between gap-3">
                      <div className="min-w-0">
                        <div className="flex flex-wrap items-center gap-2">
                          {req.ticketCode && (
                            <span className="rounded-md bg-sidebar px-2 py-0.5 text-xs font-mono font-semibold text-fg">
                              #{req.ticketCode}
                            </span>
                          )}
                          <p className="font-medium text-fg truncate">{req.title}</p>
                          <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${priorityColor(req.priority)}`}>
                            {priorityLabel(req.priority)}
                          </span>
                        </div>
                        <p className="mt-1 text-xs text-fg-muted">Phòng {req.room?.roomNumber || '-'} • {req.tenant?.fullName || '-'}</p>
                      </div>
                      <Badge status={req.status} />
                    </CardContent>
                  </Card>
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
    </Layout>
  )
}
