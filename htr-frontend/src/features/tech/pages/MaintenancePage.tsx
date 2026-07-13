import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CheckCircle, Play, FileText, Clock, Plus, Trash2, Send, CheckSquare, Package } from 'lucide-react'
import { maintenanceApi } from '@/api'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate, formatCurrency, priorityColor, priorityLabel, categoryLabel } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { MaintenanceMaterial, MaintenanceNote, MaintenanceRequest } from '@/types'

export default function TechMaintenancePage() {
  const qc = useQueryClient()
  const [activeTab, setActiveTab] = useState<'ALL' | 'IN_PROGRESS' | 'ASSIGNED' | 'DONE'>('ALL')
  
  // Work modal / expanded section state
  const [selectedRequestId, setSelectedRequestId] = useState<string | null>(null)
  
  // Slot booking state
  const [slotInputs, setSlotInputs] = useState<Record<string, string>>({})

  // New Material input state
  const [matName, setMatName] = useState('')
  const [matQty, setMatQty] = useState(1)
  const [matUnit, setMatUnit] = useState('cái')
  const [matPrice, setMatPrice] = useState('')
  const [matFree, setMatFree] = useState(false)

  // New Note input state
  const [noteText, setNoteText] = useState('')

  const { data: requests = [], isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tech-maintenance'],
    queryFn: () => maintenanceApi.listAssigned(),
  })

  // Selected request materials & notes
  const { data: materials = [], isLoading: loadingMats } = useQuery<MaintenanceMaterial[]>({
    queryKey: ['tech-maintenance-mats', selectedRequestId],
    queryFn: () => (selectedRequestId ? maintenanceApi.listMaterials(selectedRequestId) : Promise.resolve([])),
    enabled: !!selectedRequestId,
  })

  const { data: notes = [], isLoading: loadingNotes } = useQuery<MaintenanceNote[]>({
    queryKey: ['tech-maintenance-notes', selectedRequestId],
    queryFn: () => (selectedRequestId ? maintenanceApi.listNotes(selectedRequestId) : Promise.resolve([])),
    enabled: !!selectedRequestId,
  })

  const startMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.startWork(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
      qc.invalidateQueries({ queryKey: ['maintenance'] })
      showToast({ message: 'Đã chuyển trạng thái sang Đang xử lý', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Không thể bắt đầu xử lý', type: 'error' })
    },
  })

  const confirmSlotMutation = useMutation({
    mutationFn: ({ id, slot }: { id: string; slot: string }) => maintenanceApi.confirmSlot(id, slot),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
      showToast({ message: 'Đã xác nhận khung giờ làm việc với khách!', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Lỗi xác nhận giờ', type: 'error' })
    },
  })

  const addMaterialMutation = useMutation({
    mutationFn: () => {
      if (!selectedRequestId) throw new Error('No selected request')
      return maintenanceApi.addMaterial(selectedRequestId, {
        name: matName.trim(),
        quantity: Number(matQty) || 1,
        unit: matUnit.trim() || 'cái',
        unitPrice: Number(matPrice) || 0,
        isFreeInContract: matFree,
      })
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tech-maintenance-mats', selectedRequestId] })
      qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
      setMatName('')
      setMatQty(1)
      setMatPrice('')
      setMatFree(false)
      showToast({ message: 'Đã thêm vật tư', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Lỗi thêm vật tư', type: 'error' })
    },
  })

  const deleteMaterialMutation = useMutation({
    mutationFn: (materialId: string) => {
      if (!selectedRequestId) throw new Error('No selected request')
      return maintenanceApi.deleteMaterial(selectedRequestId, materialId)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tech-maintenance-mats', selectedRequestId] })
      qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
      showToast({ message: 'Đã xóa vật tư', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Lỗi xóa vật tư', type: 'error' })
    },
  })

  const addNoteMutation = useMutation({
    mutationFn: () => {
      if (!selectedRequestId) throw new Error('No selected request')
      return maintenanceApi.addNote(selectedRequestId, noteText.trim())
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tech-maintenance-notes', selectedRequestId] })
      setNoteText('')
      showToast({ message: 'Đã ghi nhận nhật ký công việc', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Lỗi thêm nhật ký', type: 'error' })
    },
  })

  const submitReviewMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.submitReview(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
      qc.invalidateQueries({ queryKey: ['maintenance'] })
      setSelectedRequestId(null)
      showToast({ message: 'Đã hoàn tất thi công & gửi yêu cầu nghiệm thu!', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Không thể gửi yêu cầu nghiệm thu', type: 'error' })
    },
  })

  const filteredRequests = requests.filter((req) => {
    if (activeTab === 'IN_PROGRESS') return req.status === 'IN_PROGRESS'
    if (activeTab === 'ASSIGNED') return req.status === 'ASSIGNED' || req.status === 'OPEN'
    if (activeTab === 'DONE') return req.status === 'COMPLETED' || req.status === 'DONE' || req.status === 'PENDING_REVIEW' || req.status === 'PENDING_PAYMENT'
    return true
  })

  const selectedRequest = requests.find((r) => r.id === selectedRequestId)

  return (
    <Layout title="Công việc của tôi">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-fg">Quản lý bảo trì (KTV)</h1>
            <p className="text-sm text-fg-muted">Theo dõi và xử lý các sự cố được phân công tại tòa nhà</p>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 border-b border-border/80 pb-3">
          <Button
            variant={activeTab === 'ALL' ? 'primary' : 'outline'}
            size="sm"
            onClick={() => setActiveTab('ALL')}
          >
            Tất cả ({requests.length})
          </Button>
          <Button
            variant={activeTab === 'ASSIGNED' ? 'primary' : 'outline'}
            size="sm"
            onClick={() => setActiveTab('ASSIGNED')}
          >
            Chưa xử lý ({requests.filter(r => r.status === 'ASSIGNED' || r.status === 'OPEN').length})
          </Button>
          <Button
            variant={activeTab === 'IN_PROGRESS' ? 'primary' : 'outline'}
            size="sm"
            onClick={() => setActiveTab('IN_PROGRESS')}
          >
            Đang thi công ({requests.filter(r => r.status === 'IN_PROGRESS').length})
          </Button>
          <Button
            variant={activeTab === 'DONE' ? 'primary' : 'outline'}
            size="sm"
            onClick={() => setActiveTab('DONE')}
          >
            Đã xong / Nghiệm thu ({requests.filter(r => r.status === 'COMPLETED' || r.status === 'DONE' || r.status === 'PENDING_REVIEW' || r.status === 'PENDING_PAYMENT').length})
          </Button>
        </div>

        {isLoading ? (
          <ListSkeleton items={4} />
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
            {/* List */}
            <div className={`${selectedRequestId ? 'lg:col-span-6' : 'lg:col-span-12'} space-y-4`}>
              {filteredRequests.map((request) => {
                const isSelected = request.id === selectedRequestId
                return (
                  <div
                    key={request.id}
                    onClick={() => setSelectedRequestId(request.id)}
                    className="cursor-pointer"
                  >
                    <Card
                      className={`border transition-all ${
                        isSelected ? 'border-accent ring-2 ring-accent/20 shadow-md' : 'border-border/80 hover:border-border'
                      }`}
                    >
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between gap-3">
                          <div className="flex-1 min-w-0 space-y-2">
                            <div className="flex flex-wrap items-center gap-2">
                              {request.ticketCode && (
                                <span className="rounded-md bg-sidebar px-2 py-0.5 text-xs font-mono font-semibold text-fg">
                                  #{request.ticketCode}
                                </span>
                              )}
                              <p className="font-semibold text-fg truncate">{request.title}</p>
                              <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${priorityColor(request.priority)}`}>
                                {priorityLabel(request.priority)}
                              </span>
                            </div>

                            <p className="text-xs font-medium text-fg-muted">
                              Phòng: <b>{request.room?.roomNumber || '-'}</b> • Khách: {request.tenant?.fullName || '-'} • Danh mục: {categoryLabel(request.category)}
                            </p>

                            {request.description && (
                              <p className="text-xs text-fg-muted line-clamp-2 bg-sidebar/50 p-2 rounded-lg">
                                {request.description}
                              </p>
                            )}

                            {/* Khung giờ ưu thích */}
                            {(request.preferredTimeSlots?.length || 0) > 0 && !request.confirmedTimeSlot && (
                              <div className="flex items-center gap-1.5 text-xs text-accent font-medium">
                                <Clock size={13} />
                                <span>Khách rảnh: {(request.preferredTimeSlots || []).join(', ')}</span>
                              </div>
                            )}

                            {request.confirmedTimeSlot && (
                              <div className="flex items-center gap-1.5 text-xs text-success font-semibold">
                                <CheckSquare size={13} />
                                <span>Lịch hẹn KTV: {request.confirmedTimeSlot}</span>
                                {request.confirmSlotByTenant && <span className="text-xs text-fg-subtle">(Khách đã duyệt)</span>}
                              </div>
                            )}

                            {request.materialCost !== undefined && request.materialCost !== null && Number(request.materialCost) > 0 && (
                              <p className="text-xs font-semibold text-amber-600 dark:text-amber-400">
                                Vật tư đã thêm: {formatCurrency(Number(request.materialCost))}
                              </p>
                            )}
                          </div>

                          <div className="flex flex-col items-end gap-2 shrink-0" onClick={(e) => e.stopPropagation()}>
                            <Badge status={request.status} />

                            {request.status === 'ASSIGNED' && (
                              <Button
                                variant="primary"
                                size="sm"
                                onClick={() => startMutation.mutate(request.id)}
                                disabled={startMutation.isPending}
                                className="flex items-center gap-1 bg-accent hover:bg-accent-hover text-accent-fg"
                              >
                                <Play size={13} />
                                Bắt đầu thi công
                              </Button>
                            )}

                            {(request.status === 'ASSIGNED' || request.status === 'OPEN') && !request.confirmedTimeSlot && (
                              <div className="flex items-center gap-1 mt-1">
                                <select
                                  className="rounded-lg border border-border bg-bg px-2 py-1 text-xs text-fg"
                                  value={slotInputs[request.id] || ''}
                                  onChange={(e) => setSlotInputs((prev) => ({ ...prev, [request.id]: e.target.value }))}
                                >
                                  <option value="">Hẹn lịch...</option>
                                  <option value="Sáng mai (8:00 - 11:30)">Sáng mai (8:00 - 11:30)</option>
                                  <option value="Chiều mai (13:30 - 17:00)">Chiều mai (13:30 - 17:00)</option>
                                  <option value="Tối nay (18:00 - 20:30)">Tối nay (18:00 - 20:30)</option>
                                  <option value="Thứ 7 tuần này">Thứ 7 tuần này</option>
                                </select>
                                <button
                                  onClick={() => {
                                    const slot = slotInputs[request.id]
                                    if (slot) confirmSlotMutation.mutate({ id: request.id, slot })
                                  }}
                                  disabled={!slotInputs[request.id] || confirmSlotMutation.isPending}
                                  className="rounded-lg bg-sidebar px-2 py-1 text-xs font-medium text-fg hover:bg-border"
                                >
                                  Chốt
                                </button>
                              </div>
                            )}

                            {request.status === 'IN_PROGRESS' && (
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setSelectedRequestId(request.id)}
                                className="flex items-center gap-1 text-xs"
                              >
                                <Package size={13} />
                                Chi tiết / Vật tư
                              </Button>
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </div>
                )
              })}

              {filteredRequests.length === 0 && (
                <div className="py-12 text-center text-fg-subtle rounded-2xl border border-dashed border-border">
                  Không có công việc nào trong danh mục này.
                </div>
              )}
            </div>

            {/* Chi tiết công việc / Vật tư & Nhật ký (Right Panel) */}
            {selectedRequest && (
              <div className="lg:col-span-6 space-y-4 animate-scale-in">
                <Card className="border border-border shadow-md">
                  <CardContent className="p-5 space-y-5">
                    <div className="flex items-start justify-between border-b border-border/80 pb-3">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-xs font-semibold text-accent">#{selectedRequest.ticketCode || selectedRequest.id.slice(0, 8)}</span>
                          <h2 className="text-lg font-bold text-fg">{selectedRequest.title}</h2>
                        </div>
                        <p className="text-xs text-fg-muted mt-1">Phòng {selectedRequest.room?.roomNumber} • Khách: {selectedRequest.tenant?.fullName}</p>
                      </div>
                      <button onClick={() => setSelectedRequestId(null)} className="text-fg-subtle hover:text-fg text-xs underline">
                        Đóng panel
                      </button>
                    </div>

                    {/* Section: Vật tư (Materials) */}
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <h3 className="text-sm font-semibold text-fg flex items-center gap-2">
                          <Package size={16} className="text-amber-500" />
                          <span>Danh sách vật tư thay thế</span>
                        </h3>
                        <span className="text-xs font-semibold text-amber-600 dark:text-amber-400">
                          Tổng: {formatCurrency(Number(selectedRequest.materialCost || 0))}
                        </span>
                      </div>

                      {loadingMats ? (
                        <ListSkeleton items={2} />
                      ) : (
                        <div className="rounded-xl border border-border/80 divide-y divide-border/60 bg-sidebar/30">
                          {materials.map((mat) => (
                            <div key={mat.id} className="flex items-center justify-between p-3 text-xs">
                              <div>
                                <p className="font-semibold text-fg">
                                  {mat.name} <span className="text-fg-muted">({mat.quantity} {mat.unit})</span>
                                </p>
                                <p className="text-[11px] text-fg-subtle">
                                  Đơn giá: {formatCurrency(mat.unitPrice)} {mat.isFreeInContract && '• Miễn phí (trong HĐ)'}
                                </p>
                              </div>
                              <div className="flex items-center gap-3">
                                <span className="font-bold text-fg">
                                  {formatCurrency(mat.totalPrice)}
                                </span>
                                {selectedRequest.status === 'IN_PROGRESS' && (
                                  <button
                                    onClick={() => deleteMaterialMutation.mutate(mat.id)}
                                    className="text-error hover:text-error/80 p-1"
                                  >
                                    <Trash2 size={13} />
                                  </button>
                                )}
                              </div>
                            </div>
                          ))}
                          {materials.length === 0 && (
                            <p className="p-3 text-center text-xs text-fg-subtle">Chưa ghi nhận vật tư nào</p>
                          )}
                        </div>
                      )}

                      {/* Add Material Form */}
                      {selectedRequest.status === 'IN_PROGRESS' && (
                        <div className="rounded-xl border border-border bg-surface p-3 space-y-2.5">
                          <p className="text-xs font-semibold text-fg">Thêm vật tư mới</p>
                          <div className="grid grid-cols-12 gap-2">
                            <input
                              type="text"
                              placeholder="Tên linh kiện (VD: Bóng đèn LED)"
                              value={matName}
                              onChange={(e) => setMatName(e.target.value)}
                              className="col-span-5 rounded-lg border border-border bg-bg px-2.5 py-1.5 text-xs text-fg focus:outline-none focus:ring-1 focus:ring-accent"
                            />
                            <input
                              type="number"
                              placeholder="SL"
                              value={matQty}
                              onChange={(e) => setMatQty(Number(e.target.value))}
                              className="col-span-2 rounded-lg border border-border bg-bg px-2 py-1.5 text-xs text-fg focus:outline-none focus:ring-1 focus:ring-accent"
                            />
                            <select
                              value={matUnit}
                              onChange={(e) => setMatUnit(e.target.value)}
                              className="col-span-2 rounded-lg border border-border bg-bg px-2 py-1.5 text-xs text-fg focus:outline-none focus:ring-1 focus:ring-accent"
                            >
                              <option value="cái">cái</option>
                              <option value="bộ">bộ</option>
                              <option value="m">m</option>
                              <option value="cuộn">cuộn</option>
                              <option value="hộp">hộp</option>
                            </select>
                            <input
                              type="number"
                              placeholder="Đơn giá VNĐ"
                              value={matPrice}
                              onChange={(e) => setMatPrice(e.target.value)}
                              className="col-span-3 rounded-lg border border-border bg-bg px-2.5 py-1.5 text-xs text-fg focus:outline-none focus:ring-1 focus:ring-accent"
                            />
                          </div>
                          <div className="flex items-center justify-between pt-1">
                            <label className="flex items-center gap-1.5 text-xs text-fg cursor-pointer">
                              <input
                                type="checkbox"
                                checked={matFree}
                                onChange={(e) => setMatFree(e.target.checked)}
                                className="rounded border-border text-accent focus:ring-accent"
                              />
                              <span>Miễn phí (do lỗi tự nhiên / bao thầu)</span>
                            </label>
                            <Button
                              size="sm"
                              variant="primary"
                              disabled={!matName.trim() || addMaterialMutation.isPending}
                              onClick={() => addMaterialMutation.mutate()}
                              className="flex items-center gap-1 h-7 px-3 text-xs bg-accent hover:bg-accent-hover text-accent-fg"
                            >
                              <Plus size={13} />
                              Thêm
                            </Button>
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Section: Nhật ký / Timeline công việc */}
                    <div className="space-y-3 pt-2 border-t border-border/80">
                      <h3 className="text-sm font-semibold text-fg flex items-center gap-2">
                        <FileText size={16} className="text-blue-500" />
                        <span>Nhật ký & Tiến độ (Notes)</span>
                      </h3>

                      {loadingNotes ? (
                        <ListSkeleton items={2} />
                      ) : (
                        <div className="max-h-44 overflow-y-auto space-y-2 rounded-xl border border-border/80 p-3 bg-sidebar/30">
                          {notes.map((n) => (
                            <div key={n.id} className="text-xs border-b border-border/40 pb-2 last:border-0 last:pb-0">
                              <div className="flex items-center justify-between text-[11px] text-fg-subtle">
                                <span className="font-semibold text-fg">{n.actorName || 'Hệ thống'}</span>
                                <span>{formatDate(n.createdAt)}</span>
                              </div>
                              <p className="mt-1 text-fg">{n.note}</p>
                            </div>
                          ))}
                          {notes.length === 0 && (
                            <p className="text-center text-xs text-fg-subtle py-2">Chưa có nhật ký nào</p>
                          )}
                        </div>
                      )}

                      {selectedRequest.status === 'IN_PROGRESS' && (
                        <div className="flex gap-2">
                          <input
                            type="text"
                            placeholder="Ghi chú tiến độ (VD: Đã tháo linh kiện, đang chờ mua đồ thay thế)..."
                            value={noteText}
                            onChange={(e) => setNoteText(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter' && noteText.trim()) addNoteMutation.mutate()
                            }}
                            className="flex-1 rounded-xl border border-border bg-surface px-3 py-1.5 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                          />
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={!noteText.trim() || addNoteMutation.isPending}
                            onClick={() => addNoteMutation.mutate()}
                            className="flex items-center gap-1 text-xs"
                          >
                            <Send size={13} />
                            Gửi note
                          </Button>
                        </div>
                      )}
                    </div>

                    {/* Action button to finish work */}
                    {selectedRequest.status === 'IN_PROGRESS' && (
                      <div className="pt-4 border-t border-border flex justify-end gap-2">
                        <Button
                          variant="primary"
                          onClick={() => submitReviewMutation.mutate(selectedRequest.id)}
                          disabled={submitReviewMutation.isPending}
                          className="w-full flex items-center justify-center gap-2 bg-success hover:bg-success/90 text-success-fg font-semibold py-2.5"
                        >
                          <CheckCircle size={16} />
                          Hoàn tất sửa chữa & Chờ nghiệm thu
                        </Button>
                      </div>
                    )}
                  </CardContent>
                </Card>
              </div>
            )}
          </div>
        )}
      </div>
    </Layout>
  )
}
