import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CheckCircle, Play, FileText } from 'lucide-react'
import { maintenanceApi } from '@/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate, formatCurrency, priorityColor, priorityLabel, categoryLabel } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { MaintenanceRequest } from '@/types'

export default function TechMaintenancePage() {
  const queryClient = useQueryClient()
  const [reviewingId, setReviewingId] = useState<string | null>(null)
  const [materialCosts, setMaterialCosts] = useState<Record<string, string>>({})

  const { data: requests = [], isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tech-maintenance'],
    queryFn: () => maintenanceApi.listAssigned(),
  })

  const startMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.start(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã bắt đầu xử lý công việc', type: 'success' })
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể bắt đầu xử lý',
        type: 'error',
      })
    },
  })

  const submitReviewMutation = useMutation({
    mutationFn: ({ id, cost }: { id: string; cost?: number }) => maintenanceApi.submitReview(id, cost),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã gửi yêu cầu nghiệm thu / thanh toán vật tư', type: 'success' })
      setReviewingId(null)
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể gửi yêu cầu nghiệm thu',
        type: 'error',
      })
    },
  })

  const resolveMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.resolve(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã hoàn thành yêu cầu bảo trì', type: 'success' })
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể cập nhật trạng thái',
        type: 'error',
      })
    },
  })

  return (
    <Layout title="Công việc">
      {isLoading ? (
        <ListSkeleton items={4} />
      ) : (
        <div className="space-y-4">
          {requests.map((request) => (
            <Card key={request.id}>
              <div className="p-4">
                <div className="flex items-start justify-between">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="font-medium text-fg">{request.title}</p>
                      {request.priority && (
                        <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${priorityColor(request.priority)}`}>
                          {priorityLabel(request.priority)}
                        </span>
                      )}
                      {request.category && (
                        <span className="inline-flex items-center rounded-full bg-sidebar px-2 py-0.5 text-[11px] font-medium text-fg-muted">
                          {categoryLabel(request.category)}
                        </span>
                      )}
                    </div>
                    <p className="mt-1 text-sm font-medium text-fg-muted">Phòng: {request.room?.roomNumber || '-'}</p>
                    {request.description && <p className="mt-2 text-sm text-fg-muted">{request.description}</p>}
                    {request.materialCost !== undefined && request.materialCost !== null && Number(request.materialCost) > 0 && (
                      <p className="mt-2 text-xs font-semibold text-accent">
                        Chi phí vật tư: {formatCurrency(Number(request.materialCost))}
                      </p>
                    )}
                    <p className="mt-3 text-xs text-fg-subtle">Ngày tạo: {formatDate(request.createdAt)}</p>
                  </div>

                  <div className="ml-4 flex shrink-0 flex-col items-end gap-2.5">
                    <Badge status={request.status} />

                    {request.status === 'ASSIGNED' && (
                      <button
                        onClick={() => startMutation.mutate(request.id)}
                        disabled={startMutation.isPending}
                        className="flex items-center gap-1.5 rounded-xl bg-accent px-3 py-1.5 text-xs font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:opacity-50"
                      >
                        <Play size={13} />
                        Bắt đầu xử lý
                      </button>
                    )}

                    {request.status === 'IN_PROGRESS' && (
                      <div className="flex flex-col items-end gap-2">
                        {reviewingId === request.id ? (
                          <div className="flex flex-col gap-2 rounded-xl border border-border/80 bg-bg p-3 shadow-sm">
                            <label className="text-xs font-medium text-fg">Chi phí vật tư (VNĐ, tùy chọn):</label>
                            <input
                              type="number"
                              placeholder="Ví dụ: 150000"
                              className="rounded-lg border border-border bg-surface px-2.5 py-1.5 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                              value={materialCosts[request.id] ?? ''}
                              onChange={(e) => setMaterialCosts((prev) => ({ ...prev, [request.id]: e.target.value }))}
                            />
                            <div className="flex justify-end gap-2 pt-1">
                              <button
                                onClick={() => setReviewingId(null)}
                                className="px-2 py-1 text-xs text-fg-muted hover:text-fg"
                              >
                                Hủy
                              </button>
                              <button
                                onClick={() => {
                                  const rawCost = materialCosts[request.id]
                                  const costNum = rawCost ? Number(rawCost) : 0
                                  submitReviewMutation.mutate({ id: request.id, cost: costNum })
                                }}
                                disabled={submitReviewMutation.isPending}
                                className="flex items-center gap-1 rounded-lg bg-accent px-2.5 py-1 text-xs font-medium text-accent-fg hover:bg-accent-hover disabled:opacity-50"
                              >
                                Gửi yêu cầu
                              </button>
                            </div>
                          </div>
                        ) : (
                          <div className="flex gap-2">
                            <button
                              onClick={() => setReviewingId(request.id)}
                              className="flex items-center gap-1.5 rounded-xl border border-border bg-surface px-3 py-1.5 text-xs font-medium text-fg hover:bg-sidebar"
                            >
                              <FileText size={13} />
                              Nghiệm thu / Vật tư
                            </button>
                            <button
                              onClick={() => resolveMutation.mutate(request.id)}
                              disabled={resolveMutation.isPending}
                              className="flex items-center gap-1.5 rounded-xl bg-success px-3 py-1.5 text-xs font-medium text-success-fg transition-colors hover:bg-success/90 disabled:opacity-50"
                            >
                              <CheckCircle size={13} />
                              Hoàn thành ngay
                            </button>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </Card>
          ))}

          {requests.length === 0 && (
            <p className="py-8 text-center text-fg-subtle">Không có công việc được giao</p>
          )}
        </div>
      )}
    </Layout>
  )
}
