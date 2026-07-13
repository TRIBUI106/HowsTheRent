import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CheckCircle, XCircle } from 'lucide-react'
import { maintenanceApi, userApi } from '@/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableCell, TableRow } from '@/components/ui/table'
import { TableSkeleton } from '@/components/ui/feedback'
import { formatDate, formatCurrency, priorityColor, priorityLabel, categoryLabel } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { MaintenanceRequest, User } from '@/types'

export default function AdminMaintenancePage() {
  const queryClient = useQueryClient()
  const [assigningId, setAssigningId] = useState<string | null>(null)
  const [selectedTech, setSelectedTech] = useState<Record<string, string>>({})
  const [cancelingId, setCancelingId] = useState<string | null>(null)
  const [cancelReasons, setCancelReasons] = useState<Record<string, string>>({})

  const { data: requests = [], isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['maintenance'],
    queryFn: () => maintenanceApi.listAll(),
  })

  const { data: users } = useQuery<User[]>({
    queryKey: ['users'],
    queryFn: () => userApi.listAll(),
  })

  const technicians = users?.filter((user) => user.role === 'TECHNICIAN') ?? []

  const assignMutation = useMutation({
    mutationFn: ({ id, techId }: { id: string; techId: string }) => maintenanceApi.assign(id, techId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã phân công kỹ thuật viên', type: 'success' })
      setAssigningId(null)
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể phân công kỹ thuật viên',
        type: 'error',
      })
    },
  })

  const cancelMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => maintenanceApi.cancel(id, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã hủy phiếu bảo trì', type: 'success' })
      setCancelingId(null)
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể hủy phiếu bảo trì',
        type: 'error',
      })
    },
  })

  const resolveMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.resolve(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã nghiệm thu / hoàn thành phiếu bảo trì', type: 'success' })
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể hoàn thành phiếu',
        type: 'error',
      })
    },
  })

  return (
    <Layout title="Quản lý Bảo trì">
      {isLoading ? (
        <TableSkeleton rows={5} columns={8} />
      ) : (
        <Card>
          <Table headers={['Tiêu đề', 'Phòng / Danh mục', 'Ưu tiên', 'Người thuê', 'Kỹ thuật viên', 'Trạng thái / Chi phí', 'Ngày tạo', 'Thao tác']}>
            {requests.map((request) => (
              <TableRow key={request.id}>
                <TableCell className="font-medium">
                  <div>
                    <p className="text-fg font-semibold">{request.title}</p>
                    {request.description && (
                      <p className="text-xs text-fg-muted mt-0.5 line-clamp-1">{request.description}</p>
                    )}
                    {request.cancelReason && (
                      <p className="text-xs text-error mt-0.5">Lý do hủy: {request.cancelReason}</p>
                    )}
                  </div>
                </TableCell>
                <TableCell>
                  <div className="flex flex-col gap-1">
                    <span className="font-medium text-fg">{request.room?.roomNumber || '-'}</span>
                    {request.category && (
                      <span className="text-[11px] text-fg-subtle">{categoryLabel(request.category)}</span>
                    )}
                  </div>
                </TableCell>
                <TableCell>
                  <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${priorityColor(request.priority)}`}>
                    {priorityLabel(request.priority)}
                  </span>
                </TableCell>
                <TableCell>{request.tenant?.fullName || '-'}</TableCell>
                <TableCell>{request.assignedTo?.fullName ?? <span className="text-fg-subtle">—</span>}</TableCell>
                <TableCell>
                  <div className="flex flex-col gap-1 items-start">
                    <Badge status={request.status} />
                    {request.materialCost !== undefined && request.materialCost !== null && Number(request.materialCost) > 0 && (
                      <span className="text-xs font-semibold text-accent">
                        Vật tư: {formatCurrency(Number(request.materialCost))}
                      </span>
                    )}
                  </div>
                </TableCell>
                <TableCell>{formatDate(request.createdAt)}</TableCell>
                <TableCell>
                  <div className="flex flex-col gap-2 items-end">
                    {(request.status === 'OPEN' || request.status === 'ASSIGNED') && (
                      assigningId === request.id ? (
                        <div className="flex items-center gap-1.5 rounded-xl border border-border/80 bg-surface p-1.5 shadow-sm">
                          <select
                            className="rounded-lg border border-border bg-bg px-2 py-1 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                            value={selectedTech[request.id] ?? ''}
                            onChange={(event) => setSelectedTech((previous) => ({ ...previous, [request.id]: event.target.value }))}
                          >
                            <option value="">Chọn KTV</option>
                            {technicians.map((technician) => (
                              <option key={technician.id} value={technician.id}>{technician.fullName}</option>
                            ))}
                          </select>
                          <button
                            onClick={() => {
                              const techId = selectedTech[request.id]
                              if (techId) assignMutation.mutate({ id: request.id, techId })
                            }}
                            disabled={!selectedTech[request.id] || assignMutation.isPending}
                            className="rounded-lg bg-accent px-2 py-1 text-xs font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:opacity-50"
                          >
                            Xác nhận
                          </button>
                          <button
                            onClick={() => setAssigningId(null)}
                            className="text-xs text-fg-muted transition-colors hover:text-fg"
                          >
                            Hủy
                          </button>
                        </div>
                      ) : (
                        <button onClick={() => setAssigningId(request.id)} className="text-xs font-medium text-accent hover:underline">
                          {request.assignedTo ? 'Đổi KTV' : 'Phân công'}
                        </button>
                      )
                    )}

                    {(request.status === 'PENDING_REVIEW' || request.status === 'PENDING_PAYMENT' || request.status === 'IN_PROGRESS') && (
                      <button
                        onClick={() => resolveMutation.mutate(request.id)}
                        disabled={resolveMutation.isPending}
                        className="flex items-center gap-1 rounded-lg bg-success px-2.5 py-1 text-xs font-medium text-success-fg hover:bg-success/90 disabled:opacity-50"
                      >
                        <CheckCircle size={13} />
                        Nghiệm thu / Xong
                      </button>
                    )}

                    {request.status !== 'COMPLETED' && request.status !== 'CANCELLED' && request.status !== 'DONE' && (
                      cancelingId === request.id ? (
                        <div className="flex flex-col gap-1.5 rounded-xl border border-border/80 bg-surface p-2 shadow-sm w-52">
                          <input
                            type="text"
                            placeholder="Nhập lý do hủy (bắt buộc)..."
                            className="w-full rounded-lg border border-border bg-bg px-2 py-1 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                            value={cancelReasons[request.id] ?? ''}
                            onChange={(e) => setCancelReasons((prev) => ({ ...prev, [request.id]: e.target.value }))}
                          />
                          <div className="flex justify-end gap-1.5">
                            <button
                              onClick={() => setCancelingId(null)}
                              className="text-xs text-fg-muted hover:text-fg"
                            >
                              Thoát
                            </button>
                            <button
                              onClick={() => {
                                const reason = (cancelReasons[request.id] ?? '').trim()
                                if (!reason) {
                                  showToast({ message: 'Vui lòng nhập lý do hủy!', type: 'error' })
                                  return
                                }
                                cancelMutation.mutate({ id: request.id, reason })
                              }}
                              disabled={cancelMutation.isPending}
                              className="rounded-lg bg-error px-2 py-1 text-xs font-medium text-error-fg hover:bg-error/90 disabled:opacity-50"
                            >
                              Xác nhận hủy
                            </button>
                          </div>
                        </div>
                      ) : (
                        <button
                          onClick={() => setCancelingId(request.id)}
                          className="flex items-center gap-1 text-xs text-error hover:underline"
                        >
                          <XCircle size={13} />
                          Hủy phiếu
                        </button>
                      )
                    )}
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}
    </Layout>
  )
}
