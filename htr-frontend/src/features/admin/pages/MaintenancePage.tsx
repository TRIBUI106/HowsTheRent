import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CheckCircle, XCircle, Search, AlertTriangle, ShieldAlert, FileText, Package } from 'lucide-react'
import { maintenanceApi, userApi } from '@/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Table, TableCell, TableRow } from '@/components/ui/table'
import { TableSkeleton, ListSkeleton } from '@/components/ui/feedback'
import { formatDate, formatCurrency, priorityColor, priorityLabel, categoryLabel } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { MaintenanceMaterial, MaintenanceNote, MaintenanceRequest, User } from '@/types'

export default function AdminMaintenancePage() {
  const qc = useQueryClient()
  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState<string>('ALL')
  const [filterPriority, setFilterPriority] = useState<string>('ALL')
  const [filterCategory, setFilterCategory] = useState<string>('ALL')

  // Inline assignment & cancel states
  const [assigningId, setAssigningId] = useState<string | null>(null)
  const [selectedTech, setSelectedTech] = useState<Record<string, string>>({})
  const [cancelingId, setCancelingId] = useState<string | null>(null)
  const [cancelReasons, setCancelReasons] = useState<Record<string, string>>({})

  // Detail Modal / Inspection panel
  const [inspectRequestId, setInspectRequestId] = useState<string | null>(null)
  const [slaDateInput, setSlaDateInput] = useState('')

  const { data: requests = [], isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['maintenance'],
    queryFn: () => maintenanceApi.listAll(),
  })

  const { data: users } = useQuery<User[]>({
    queryKey: ['users'],
    queryFn: () => userApi.listAll(),
  })

  const technicians = users?.filter((user) => user.role === 'TECHNICIAN') ?? []
  const inspectRequest = requests.find((r) => r.id === inspectRequestId)

  const { data: inspectMaterials = [], isLoading: loadingMats } = useQuery<MaintenanceMaterial[]>({
    queryKey: ['admin-maintenance-mats', inspectRequestId],
    queryFn: () => (inspectRequestId ? maintenanceApi.listMaterials(inspectRequestId) : Promise.resolve([])),
    enabled: !!inspectRequestId,
  })

  const { data: inspectNotes = [], isLoading: loadingNotes } = useQuery<MaintenanceNote[]>({
    queryKey: ['admin-maintenance-notes', inspectRequestId],
    queryFn: () => (inspectRequestId ? maintenanceApi.listNotes(inspectRequestId) : Promise.resolve([])),
    enabled: !!inspectRequestId,
  })

  const assignMutation = useMutation({
    mutationFn: ({ id, techId }: { id: string; techId: string }) => maintenanceApi.assign(id, techId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['maintenance'] })
      qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã phân công Kỹ thuật viên thành công', type: 'success' })
      setAssigningId(null)
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Không thể phân công', type: 'error' })
    },
  })

  const cancelMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => maintenanceApi.cancel(id, reason),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['maintenance'] })
      qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã hủy phiếu bảo trì', type: 'success' })
      setCancelingId(null)
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Không thể hủy phiếu', type: 'error' })
    },
  })

  const resolveMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.resolve(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['maintenance'] })
      qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã hoàn thành / nghiệm thu phiếu bảo trì', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Không thể hoàn thành phiếu', type: 'error' })
    },
  })

  const updateSlaMutation = useMutation({
    mutationFn: ({ id, date }: { id: string; date: string }) => maintenanceApi.updateSla(id, date),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['maintenance'] })
      showToast({ message: 'Đã cập nhật mốc thời gian SLA', type: 'success' })
      setSlaDateInput('')
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Lỗi cập nhật SLA', type: 'error' })
    },
  })

  // Filtering
  const filtered = requests.filter((r) => {
    if (filterStatus !== 'ALL' && r.status !== filterStatus) return false
    if (filterPriority !== 'ALL' && r.priority !== filterPriority) return false
    if (filterCategory !== 'ALL' && r.category !== filterCategory) return false
    if (search.trim()) {
      const s = search.toLowerCase()
      const matchTitle = r.title.toLowerCase().includes(s)
      const matchCode = (r.ticketCode || '').toLowerCase().includes(s)
      const matchRoom = (r.room?.roomNumber || '').toLowerCase().includes(s)
      const matchTenant = (r.tenant?.fullName || '').toLowerCase().includes(s)
      return matchTitle || matchCode || matchRoom || matchTenant
    }
    return true
  })

  return (
    <Layout title="Quản lý Bảo trì">
      <div className="space-y-4">
        {/* Header & Filters */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-fg">Danh sách sự cố & Bảo trì</h1>
            <p className="text-sm text-fg-muted">Giám sát SLA, phân công kỹ thuật viên và kiểm soát chi phí vật tư</p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-fg-subtle" />
              <input
                type="text"
                placeholder="Tìm mã phiếu, phòng, tên..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-56 rounded-xl border border-border bg-surface pl-9 pr-3 py-1.5 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
              />
            </div>

            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="rounded-xl border border-border bg-surface px-2.5 py-1.5 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
            >
              <option value="ALL">Tất cả trạng thái</option>
              <option value="OPEN">Mới (OPEN)</option>
              <option value="ASSIGNED">Đã phân công</option>
              <option value="IN_PROGRESS">Đang thi công</option>
              <option value="PENDING_PAYMENT">Chờ thanh toán vật tư</option>
              <option value="PENDING_REVIEW">Chờ nghiệm thu</option>
              <option value="COMPLETED">Đã hoàn thành</option>
              <option value="CANCELLED">Đã hủy</option>
            </select>

            <select
              value={filterPriority}
              onChange={(e) => setFilterPriority(e.target.value)}
              className="rounded-xl border border-border bg-surface px-2.5 py-1.5 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
            >
              <option value="ALL">Tất cả độ ưu tiên</option>
              <option value="URGENT">Khẩn cấp</option>
              <option value="HIGH">Ưu tiên cao</option>
              <option value="NORMAL">Bình thường</option>
            </select>

            <select
              value={filterCategory}
              onChange={(e) => setFilterCategory(e.target.value)}
              className="rounded-xl border border-border bg-surface px-2.5 py-1.5 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
            >
              <option value="ALL">Tất cả danh mục</option>
              <option value="ELECTRIC">Điện</option>
              <option value="PLUMBING">Nước / Đường ống</option>
              <option value="AIR_CONDITIONER">Điều hòa</option>
              <option value="FURNITURE">Nội thất</option>
              <option value="OTHER">Khác</option>
            </select>
          </div>
        </div>

        {/* Modal Kiểm tra chi tiết phiếu (Vật tư, SLA, Timeline) */}
        {inspectRequest && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
            <Card className="max-h-[90vh] w-full max-w-2xl overflow-y-auto animate-scale-in p-6">
              <div className="flex items-start justify-between border-b border-border/80 pb-3 mb-4">
                <div>
                  <div className="flex items-center gap-2">
                    {inspectRequest.ticketCode && (
                      <span className="rounded-md bg-sidebar px-2 py-0.5 font-mono text-xs font-semibold text-accent">
                        #{inspectRequest.ticketCode}
                      </span>
                    )}
                    <h2 className="text-lg font-bold text-fg">{inspectRequest.title}</h2>
                    <Badge status={inspectRequest.status} />
                  </div>
                  <p className="text-xs text-fg-muted mt-1">
                    Phòng {inspectRequest.room?.roomNumber} • Khách thuê: {inspectRequest.tenant?.fullName} • KTV: {inspectRequest.assignedTo?.fullName || 'Chưa phân công'}
                  </p>
                </div>
                <button onClick={() => setInspectRequestId(null)} className="text-fg-subtle hover:text-fg text-sm">
                  ✕
                </button>
              </div>

              {/* SLA & Time info */}
              <div className="grid grid-cols-2 gap-3 mb-4 p-3 rounded-xl bg-sidebar/50 border border-border/60 text-xs">
                <div>
                  <p className="text-fg-subtle">Hạn xử lý SLA (Expected Resolved):</p>
                  <div className="mt-1 flex items-center gap-2">
                    <span className="font-semibold text-fg">
                      {inspectRequest.expectedResolvedAt ? formatDate(inspectRequest.expectedResolvedAt) : 'Chưa đặt mốc SLA'}
                    </span>
                    {inspectRequest.isOverdueSla && (
                      <span className="inline-flex items-center gap-1 text-error font-bold">
                        <AlertTriangle size={13} /> Quá hạn SLA!
                      </span>
                    )}
                  </div>
                </div>
                <div>
                  <p className="text-fg-subtle">Cập nhật hạn SLA mới:</p>
                  <div className="mt-1 flex items-center gap-2">
                    <input
                      type="datetime-local"
                      value={slaDateInput}
                      onChange={(e) => setSlaDateInput(e.target.value)}
                      className="rounded-lg border border-border bg-surface px-2 py-1 text-xs text-fg"
                    />
                    <button
                      onClick={() => {
                        if (slaDateInput) updateSlaMutation.mutate({ id: inspectRequest.id, date: new Date(slaDateInput).toISOString() })
                      }}
                      disabled={!slaDateInput || updateSlaMutation.isPending}
                      className="rounded-lg bg-accent px-2 py-1 font-semibold text-accent-fg hover:bg-accent-hover disabled:opacity-50"
                    >
                      Lưu
                    </button>
                  </div>
                </div>
              </div>

              {/* Khiếu nại info */}
              {inspectRequest.isComplained && (
                <div className="mb-4 rounded-xl border border-error/40 bg-error/10 p-3 text-xs text-error">
                  <p className="font-bold flex items-center gap-1.5">
                    <ShieldAlert size={15} /> Khách đang khiếu nại / phản hồi chất lượng:
                  </p>
                  <p className="mt-1 text-error/90 font-medium">{inspectRequest.complainReason || 'Chưa hài lòng với kết quả sửa chữa'}</p>
                </div>
              )}

              {/* Vật tư itemized */}
              <div className="space-y-2 mb-4">
                <div className="flex items-center justify-between text-xs font-semibold text-fg">
                  <span className="flex items-center gap-1.5"><Package size={14} className="text-amber-500" /> Vật tư thay thế</span>
                  <span className="text-amber-600 dark:text-amber-400">Tổng: {formatCurrency(Number(inspectRequest.materialCost || 0))}</span>
                </div>
                {loadingMats ? (
                  <ListSkeleton items={2} />
                ) : (
                  <div className="rounded-xl border border-border/80 divide-y divide-border/60 bg-surface text-xs">
                    {inspectMaterials.map((mat) => (
                      <div key={mat.id} className="flex justify-between p-2.5">
                        <span>{mat.name} ({mat.quantity} {mat.unit}) {mat.isFreeInContract && '• Miễn phí'}</span>
                        <span className="font-bold">{formatCurrency(mat.totalPrice)}</span>
                      </div>
                    ))}
                    {inspectMaterials.length === 0 && <p className="p-3 text-center text-fg-subtle">Không có vật tư phát sinh</p>}
                  </div>
                )}
              </div>

              {/* Timeline Notes */}
              <div className="space-y-2">
                <p className="text-xs font-semibold text-fg flex items-center gap-1.5">
                  <FileText size={14} className="text-blue-500" /> Lịch sử xử lý & Nhật ký
                </p>
                {loadingNotes ? (
                  <ListSkeleton items={2} />
                ) : (
                  <div className="max-h-40 overflow-y-auto space-y-2 rounded-xl border border-border/80 p-3 bg-sidebar/30 text-xs">
                    {inspectNotes.map((n) => (
                      <div key={n.id} className="border-b border-border/40 pb-1.5 last:border-0 last:pb-0">
                        <div className="flex justify-between font-semibold text-fg">
                          <span>{n.actorName || 'Hệ thống'}</span>
                          <span className="font-normal text-fg-subtle">{formatDate(n.createdAt)}</span>
                        </div>
                        <p className="mt-0.5 text-fg-muted">{n.note}</p>
                      </div>
                    ))}
                    {inspectNotes.length === 0 && <p className="text-center text-fg-subtle py-2">Chưa có nhật ký</p>}
                  </div>
                )}
              </div>

              <div className="mt-5 flex justify-end">
                <Button variant="outline" onClick={() => setInspectRequestId(null)}>
                  Đóng cửa sổ
                </Button>
              </div>
            </Card>
          </div>
        )}

        {/* Table */}
        {isLoading ? (
          <TableSkeleton rows={6} columns={8} />
        ) : (
          <Card>
            <Table headers={['Mã & Tiêu đề', 'Phòng & Danh mục', 'Ưu tiên / SLA', 'Khách & KTV', 'Trạng thái & Chi phí', 'Ngày tạo', 'Thao tác']}>
              {filtered.map((request) => (
                <TableRow key={request.id}>
                  <TableCell className="font-medium max-w-[220px]">
                    <div>
                      <div className="flex items-center gap-1.5">
                        {request.ticketCode && (
                          <span className="rounded bg-sidebar px-1.5 py-0.5 font-mono text-[11px] font-bold text-accent">
                            #{request.ticketCode}
                          </span>
                        )}
                        <span className="text-fg font-semibold truncate">{request.title}</span>
                      </div>
                      {request.description && (
                        <p className="text-xs text-fg-muted mt-0.5 line-clamp-1">{request.description}</p>
                      )}
                      {request.isComplained && (
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-error mt-0.5">
                          <ShieldAlert size={12} /> Có khiếu nại!
                        </span>
                      )}
                      {request.cancelReason && (
                        <p className="text-xs text-error mt-0.5">Lý do hủy: {request.cancelReason}</p>
                      )}
                    </div>
                  </TableCell>

                  <TableCell>
                    <div className="flex flex-col gap-1">
                      <span className="font-semibold text-fg">{request.room?.roomNumber || '-'}</span>
                      {request.category && (
                        <span className="text-[11px] text-fg-subtle">{categoryLabel(request.category)}</span>
                      )}
                    </div>
                  </TableCell>

                  <TableCell>
                    <div className="flex flex-col gap-1 items-start">
                      <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${priorityColor(request.priority)}`}>
                        {priorityLabel(request.priority)}
                      </span>
                      {request.isOverdueSla && (
                        <span className="inline-flex items-center gap-0.5 text-[11px] font-bold text-error">
                          <AlertTriangle size={12} /> Quá hạn SLA
                        </span>
                      )}
                    </div>
                  </TableCell>

                  <TableCell>
                    <div className="text-xs space-y-0.5">
                      <p className="text-fg font-medium">K: {request.tenant?.fullName || '-'}</p>
                      <p className="text-fg-muted">
                        KTV: {request.assignedTo?.fullName ?? <span className="text-error font-medium">Chưa chọn</span>}
                      </p>
                    </div>
                  </TableCell>

                  <TableCell>
                    <div className="flex flex-col gap-1 items-start">
                      <Badge status={request.status} />
                      {request.materialCost !== undefined && request.materialCost !== null && Number(request.materialCost) > 0 && (
                        <span className="text-xs font-semibold text-amber-600 dark:text-amber-400">
                          Vật tư: {formatCurrency(Number(request.materialCost))}
                        </span>
                      )}
                    </div>
                  </TableCell>

                  <TableCell className="text-xs text-fg-muted">{formatDate(request.createdAt)}</TableCell>

                  <TableCell>
                    <div className="flex flex-col gap-1.5 items-end">
                      <button
                        onClick={() => setInspectRequestId(request.id)}
                        className="text-xs font-semibold text-accent hover:underline flex items-center gap-1"
                      >
                        <FileText size={13} />
                        Chi tiết / SLA
                      </button>

                      {/* Phân công KTV */}
                      {(request.status === 'OPEN' || request.status === 'ASSIGNED') && (
                        assigningId === request.id ? (
                          <div className="flex items-center gap-1.5 rounded-xl border border-border/80 bg-surface p-1.5 shadow-sm">
                            <select
                              className="rounded-lg border border-border bg-bg px-2 py-1 text-xs text-fg focus:outline-none focus:ring-1 focus:ring-accent"
                              value={selectedTech[request.id] ?? ''}
                              onChange={(event) => setSelectedTech((prev) => ({ ...prev, [request.id]: event.target.value }))}
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
                              className="rounded-lg bg-accent px-2 py-1 text-xs font-medium text-accent-fg hover:bg-accent-hover disabled:opacity-50"
                            >
                              Chốt
                            </button>
                            <button onClick={() => setAssigningId(null)} className="text-xs text-fg-muted hover:text-fg">
                              Hủy
                            </button>
                          </div>
                        ) : (
                          <button onClick={() => setAssigningId(request.id)} className="text-xs font-medium text-blue-600 dark:text-blue-400 hover:underline">
                            {request.assignedTo ? 'Đổi KTV' : '+ Phân công KTV'}
                          </button>
                        )
                      )}

                      {/* Nghiệm thu / Xong */}
                      {(request.status === 'PENDING_REVIEW' || request.status === 'IN_PROGRESS' || request.status === 'PENDING_PAYMENT') && (
                        <button
                          onClick={() => resolveMutation.mutate(request.id)}
                          disabled={resolveMutation.isPending}
                          className="flex items-center gap-1 rounded-lg bg-success px-2.5 py-1 text-xs font-medium text-success-fg hover:bg-success/90 disabled:opacity-50"
                        >
                          <CheckCircle size={13} />
                          Nghiệm thu
                        </button>
                      )}

                      {/* Hủy phiếu */}
                      {request.status !== 'COMPLETED' && request.status !== 'CANCELLED' && request.status !== 'DONE' && (
                        cancelingId === request.id ? (
                          <div className="flex flex-col gap-1.5 rounded-xl border border-border/80 bg-surface p-2 shadow-sm w-52 z-10">
                            <input
                              type="text"
                              placeholder="Lý do hủy (bắt buộc >10 ký tự)..."
                              className="w-full rounded-lg border border-border bg-bg px-2 py-1 text-xs text-fg focus:outline-none focus:ring-1 focus:ring-accent"
                              value={cancelReasons[request.id] ?? ''}
                              onChange={(e) => setCancelReasons((prev) => ({ ...prev, [request.id]: e.target.value }))}
                            />
                            <div className="flex justify-end gap-1.5">
                              <button onClick={() => setCancelingId(null)} className="text-xs text-fg-muted hover:text-fg">
                                Thoát
                              </button>
                              <button
                                onClick={() => {
                                  const reason = (cancelReasons[request.id] ?? '').trim()
                                  if (reason.length < 10) {
                                    showToast({ message: 'Lý do hủy phải dài từ 10 ký tự trở lên!', type: 'error' })
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
                          <button onClick={() => setCancelingId(request.id)} className="flex items-center gap-1 text-xs text-error hover:underline">
                            <XCircle size={13} />
                            Hủy
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
      </div>
    </Layout>
  )
}
