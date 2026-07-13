import { useQuery } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { CardsSkeleton, TableSkeleton } from '@/components/ui/feedback'
import { reportApi } from '@/api/reportApi'
import type { MaintenanceReportSummary } from '@/types'
import {
  BarChart3, Download, Clock, CheckCircle2, AlertTriangle,
  Wrench, Star, UserCheck, ShieldAlert,
} from 'lucide-react'

export default function ReportsPage() {
  const { data: summary, isLoading, error } = useQuery<MaintenanceReportSummary>({
    queryKey: ['maintenance-report-summary'],
    queryFn: reportApi.getSummary,
  })

  const categoryLabels: Record<string, string> = {
    ELECTRIC: 'Điện',
    PLUMBING: 'Nước / Đường ống',
    AIR_CONDITIONER: 'Điều hòa / Máy lạnh',
    FURNITURE: 'Nội thất',
    OTHER: 'Khác',
  }

  const priorityLabels: Record<string, { label: string; color: string }> = {
    NORMAL: { label: 'Bình thường', color: 'bg-blue-100 text-blue-800' },
    HIGH: { label: 'Cao', color: 'bg-amber-100 text-amber-800' },
    URGENT: { label: 'Khẩn cấp', color: 'bg-red-100 text-red-800' },
  }

  return (
    <Layout>
      <div className="space-y-8 max-w-7xl mx-auto py-6 px-4 sm:px-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b pb-4">
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-gray-900 flex items-center gap-2.5">
              <BarChart3 className="w-7 h-7 text-indigo-600" />
              Báo Cáo & Phân Tích KPI Bảo Trì
            </h1>
            <p className="text-sm text-gray-500 mt-1">
              Theo dõi tình trạng xử lý sự cố, hiệu suất kỹ thuật viên, cam kết SLA và chi phí bảo trì.
            </p>
          </div>
          <Button
            onClick={() => reportApi.exportCsv()}
            className="bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl py-2.5 px-4 font-medium flex items-center gap-2 shadow-sm"
          >
            <Download className="w-4 h-4" />
            Xuất Báo Cáo Excel / CSV
          </Button>
        </div>

        {error && (
          <div className="p-4 bg-red-50 text-red-700 rounded-xl border border-red-200">
            Không thể tải dữ liệu báo cáo. Vui lòng thử lại sau.
          </div>
        )}

        {isLoading ? (
          <div className="space-y-6">
            <CardsSkeleton count={6} />
            <TableSkeleton columns={6} rows={5} />
          </div>
        ) : summary && (
          <>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
              <Card className="p-5 border border-gray-200 shadow-sm rounded-2xl bg-white flex flex-col justify-between">
                <div className="text-xs font-semibold text-gray-500 uppercase">Tổng số phiếu</div>
                <div className="text-2xl font-bold text-gray-900 mt-2">{summary.totalTickets}</div>
                <div className="text-xs text-indigo-600 mt-1 font-medium flex items-center gap-1">
                  <Wrench className="w-3.5 h-3.5" /> Toàn bộ hệ thống
                </div>
              </Card>

              <Card className="p-5 border border-gray-200 shadow-sm rounded-2xl bg-white flex flex-col justify-between">
                <div className="text-xs font-semibold text-gray-500 uppercase">Đã hoàn tất</div>
                <div className="text-2xl font-bold text-emerald-600 mt-2">{summary.completedTickets}</div>
                <div className="text-xs text-emerald-600 mt-1 font-medium flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" /> Thành công
                </div>
              </Card>

              <Card className="p-5 border border-gray-200 shadow-sm rounded-2xl bg-white flex flex-col justify-between">
                <div className="text-xs font-semibold text-gray-500 uppercase">Đang xử lý</div>
                <div className="text-2xl font-bold text-blue-600 mt-2">{summary.inProgressTickets}</div>
                <div className="text-xs text-blue-600 mt-1 font-medium flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5" /> Đã phân công/Thực hiện
                </div>
              </Card>

              <Card className="p-5 border border-gray-200 shadow-sm rounded-2xl bg-white flex flex-col justify-between">
                <div className="text-xs font-semibold text-gray-500 uppercase">Đang mở / Chờ</div>
                <div className="text-2xl font-bold text-amber-600 mt-2">{summary.openTickets}</div>
                <div className="text-xs text-amber-600 mt-1 font-medium flex items-center gap-1">
                  <AlertTriangle className="w-3.5 h-3.5" /> Cần tiếp nhận
                </div>
              </Card>

              <Card className="p-5 border border-red-200 shadow-sm rounded-2xl bg-red-50/60 flex flex-col justify-between">
                <div className="text-xs font-semibold text-red-700 uppercase">Quá hạn SLA</div>
                <div className="text-2xl font-bold text-red-600 mt-2">{summary.overdueSlaTickets}</div>
                <div className="text-xs text-red-700 mt-1 font-medium flex items-center gap-1">
                  <ShieldAlert className="w-3.5 h-3.5" /> Vi phạm cam kết
                </div>
              </Card>

              <Card className="p-5 border border-gray-200 shadow-sm rounded-2xl bg-white flex flex-col justify-between">
                <div className="text-xs font-semibold text-gray-500 uppercase">Thời gian xử lý TB</div>
                <div className="text-2xl font-bold text-indigo-600 mt-2">{summary.avgResolutionHours} <span className="text-sm font-normal text-gray-500">giờ</span></div>
                <div className="text-xs text-gray-500 mt-1 font-medium">Trung bình từ Mở - Xong</div>
              </Card>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card className="p-6 rounded-2xl border border-gray-200 shadow-sm bg-white space-y-4">
                <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2 border-b pb-3">
                  <Wrench className="w-5 h-5 text-indigo-600" /> Phân bổ theo Danh mục sự cố
                </h2>
                <div className="space-y-3">
                  {Object.entries(summary.byCategory || {}).length === 0 ? (
                    <p className="text-sm text-gray-400 py-4 text-center">Chưa có dữ liệu theo danh mục.</p>
                  ) : (
                    Object.entries(summary.byCategory || {}).map(([catKey, count]) => {
                      const total = summary.totalTickets > 0 ? summary.totalTickets : 1
                      const percentage = Math.round((count / total) * 100)
                      return (
                        <div key={catKey} className="space-y-1">
                          <div className="flex justify-between text-sm font-medium text-gray-700">
                            <span>{categoryLabels[catKey] ?? catKey}</span>
                            <span className="font-bold text-gray-900">{count} phiếu ({percentage}%)</span>
                          </div>
                          <div className="w-full bg-gray-100 h-2.5 rounded-full overflow-hidden">
                            <div className="bg-indigo-600 h-2.5 rounded-full" style={{ width: `${percentage}%` }} />
                          </div>
                        </div>
                      )
                    })
                  )}
                </div>
              </Card>

              <Card className="p-6 rounded-2xl border border-gray-200 shadow-sm bg-white space-y-4">
                <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2 border-b pb-3">
                  <AlertTriangle className="w-5 h-5 text-amber-600" /> Phân bổ theo Độ ưu tiên
                </h2>
                <div className="space-y-3">
                  {Object.entries(summary.byPriority || {}).length === 0 ? (
                    <p className="text-sm text-gray-400 py-4 text-center">Chưa có dữ liệu theo độ ưu tiên.</p>
                  ) : (
                    Object.entries(summary.byPriority || {}).map(([prioKey, count]) => {
                      const total = summary.totalTickets > 0 ? summary.totalTickets : 1
                      const percentage = Math.round((count / total) * 100)
                      const info = priorityLabels[prioKey] ?? { label: prioKey, color: 'bg-gray-100 text-gray-800' }
                      return (
                        <div key={prioKey} className="space-y-1">
                          <div className="flex justify-between text-sm font-medium text-gray-700">
                            <span className="flex items-center gap-2">
                              <Badge className={`${info.color}`}>{info.label}</Badge>
                            </span>
                            <span className="font-bold text-gray-900">{count} phiếu ({percentage}%)</span>
                          </div>
                          <div className="w-full bg-gray-100 h-2.5 rounded-full overflow-hidden">
                            <div className={`h-2.5 rounded-full ${prioKey === 'URGENT' ? 'bg-red-500' : prioKey === 'HIGH' ? 'bg-amber-500' : 'bg-blue-500'}`} style={{ width: `${percentage}%` }} />
                          </div>
                        </div>
                      )
                    })
                  )}
                </div>
              </Card>
            </div>

            <Card className="p-6 rounded-2xl border border-gray-200 shadow-sm bg-white space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 border-b pb-3">
                <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                  <UserCheck className="w-5 h-5 text-indigo-600" />
                  Hiệu Suất Kỹ Thuật Viên & Đánh Giá Chất Lượng
                </h2>
                <span className="text-xs font-medium text-gray-500">Giới hạn đồng thời tối đa: 5 phiếu active/KTV</span>
              </div>

              {summary.technicianPerformance && summary.technicianPerformance.length === 0 ? (
                <div className="text-center py-8 text-gray-500">Chưa có kỹ thuật viên nào trong hệ thống.</div>
              ) : (
                <div className="overflow-x-auto rounded-xl border border-gray-200">
                  <table className="min-w-full divide-y divide-gray-200 text-sm">
                    <thead className="bg-gray-50 text-gray-600 font-medium">
                      <tr>
                        <th className="px-4 py-3 text-left">Kỹ thuật viên</th>
                        <th className="px-4 py-3 text-left">Chuyên môn</th>
                        <th className="px-4 py-3 text-center">Đã giao</th>
                        <th className="px-4 py-3 text-center">Đang làm (Active)</th>
                        <th className="px-4 py-3 text-center">Hoàn tất</th>
                        <th className="px-4 py-3 text-center">Quá hạn SLA</th>
                        <th className="px-4 py-3 text-right">Đánh giá trung bình</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 bg-white">
                      {summary.technicianPerformance.map((tech) => {
                        const isAtLimit = tech.activeCount >= 5
                        return (
                          <tr key={tech.technicianId} className="hover:bg-gray-50/60 transition">
                            <td className="px-4 py-3 font-semibold text-gray-900">{tech.technicianName}</td>
                            <td className="px-4 py-3">
                              <div className="flex flex-wrap gap-1">
                                {(tech.specialties || 'OTHER').split(',').map((s) => (
                                  <Badge key={s} variant="outline" className="text-xs bg-gray-50 border-gray-200 font-normal">
                                    {categoryLabels[s.trim()] ?? s.trim()}
                                  </Badge>
                                ))}
                              </div>
                            </td>
                            <td className="px-4 py-3 text-center font-medium text-gray-700">{tech.assignedCount}</td>
                            <td className="px-4 py-3 text-center">
                              <Badge className={isAtLimit ? 'bg-red-100 text-red-800 font-bold' : 'bg-blue-100 text-blue-800 font-medium'}>
                                {tech.activeCount} / 5
                              </Badge>
                            </td>
                            <td className="px-4 py-3 text-center font-bold text-emerald-600">{tech.completedCount}</td>
                            <td className="px-4 py-3 text-center">
                              {tech.overdueSlaCount > 0 ? (
                                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-red-100 text-red-800">
                                  {tech.overdueSlaCount}
                                </span>
                              ) : (
                                <span className="text-gray-400">0</span>
                              )}
                            </td>
                            <td className="px-4 py-3 text-right">
                              <div className="inline-flex items-center gap-1.5 font-bold text-amber-600 bg-amber-50 px-3 py-1 rounded-full border border-amber-200 text-xs">
                                <Star className="w-3.5 h-3.5 fill-amber-500" />
                                {tech.avgRatingStars.toFixed(1)} / 5.0
                                <span className="text-gray-500 font-normal">({tech.totalReviews} đánh giá)</span>
                              </div>
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </Card>
          </>
        )}
      </div>
    </Layout>
  )
}
