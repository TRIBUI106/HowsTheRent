import { useRef, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Camera, Video, X, Clock, AlertTriangle, CheckCircle, CreditCard, ShieldAlert, Star } from 'lucide-react'
import api from '@/lib/api'
import { maintenanceApi, reportApi } from '@/api'
import { extractPageContent, getRoomPropertyName, normalizeContract } from '@/lib/apiMappers'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate, formatCurrency, priorityColor, priorityLabel, categoryLabel } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { Contract, MaintenanceRequest } from '@/types'

const AVAILABLE_SLOTS = [
  'Sáng (08:00 - 11:30)',
  'Chiều (13:30 - 17:00)',
  'Tối (18:00 - 20:30)',
  'Cuối tuần (Thứ 7 - CN)'
]

export default function TenantMaintenancePage() {
  const qc = useQueryClient()
  const fileRef = useRef<HTMLInputElement>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState<'NORMAL' | 'HIGH' | 'URGENT'>('NORMAL')
  const [category, setCategory] = useState<'ELECTRIC' | 'PLUMBING' | 'AIR_CONDITIONER' | 'FURNITURE' | 'OTHER'>('OTHER')
  const [preferredSlots, setPreferredSlots] = useState<string[]>([])
  const [images, setImages] = useState<File[]>([])
  const [video, setVideo] = useState<File | null>(null)
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const [error, setError] = useState('')

  // Complain Modal State
  const [complainModalId, setComplainModalId] = useState<string | null>(null)
  const [complainReason, setComplainReason] = useState('')

  // Review Modal State
  const [reviewModalId, setReviewModalId] = useState<string | null>(null)
  const [ratingStars, setRatingStars] = useState<number>(5)
  const [reviewComment, setReviewComment] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['tenant-maintenance'],
    queryFn: () => maintenanceApi.listMine(),
  })

  const { data: contractsData } = useQuery({
    queryKey: ['tenant-contracts'],
    queryFn: () => api.get('/contracts/mine').then((r) => r.data),
  })

  const requests: MaintenanceRequest[] = (data || []) as MaintenanceRequest[]
  const activeContracts: Contract[] = extractPageContent<any>(contractsData)
    .map(normalizeContract)
    .filter((contract) => contract.status === 'ACTIVE')
  const activeRoom = activeContracts[0]?.room

  function clearPreviews() {
    previewUrls.forEach((url) => URL.revokeObjectURL(url))
    setPreviewUrls([])
  }

  function resetForm() {
    setTitle('')
    setDescription('')
    setPriority('NORMAL')
    setCategory('OTHER')
    setPreferredSlots([])
    setImages([])
    setVideo(null)
    clearPreviews()
    setError('')
  }

  const createMutation = useMutation({
    mutationFn: () => {
      const form = new FormData()
      form.append('title', title.trim())
      if (description.trim()) form.append('description', description.trim())
      form.append('priority', priority)
      form.append('category', category)
      preferredSlots.forEach((slot) => form.append('preferredTimeSlots', slot))
      images.forEach((image) => form.append('images', image))
      if (video) form.append('video', video)
      return api.post('/maintenance/with-images', form)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
      setShowCreate(false)
      resetForm()
      showToast({ message: 'Đã gửi yêu cầu bảo trì thành công', type: 'success' })
    },
    onError: (err: any) => {
      const message = err?.response?.data?.message ?? 'Lỗi khi tạo yêu cầu bảo trì'
      setError(message)
      showToast({ message, type: 'error' })
    },
  })

  const resolveMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.resolve(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã nghiệm thu và hoàn thành phiếu bảo trì!', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Không thể nghiệm thu', type: 'error' })
    },
  })

  const complainMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => maintenanceApi.complain(id, reason),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      setComplainModalId(null)
      setComplainReason('')
      showToast({ message: 'Đã gửi phản hồi / khiếu nại thành công!', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Lỗi khi khiếu nại', type: 'error' })
    },
  })

  const reviewMutation = useMutation({
    mutationFn: ({ id, stars, comment }: { id: string; stars: number; comment?: string }) => reportApi.createReview(id, stars, comment),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      setReviewModalId(null)
      setReviewComment('')
      showToast({ message: 'Đã gửi đánh giá chất lượng dịch vụ bảo trì!', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Không thể gửi đánh giá', type: 'error' })
    },
  })

  const payMaterialMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.payMaterial(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      showToast({ message: 'Đã thanh toán chi phí vật tư!', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Lỗi khi thanh toán vật tư', type: 'error' })
    },
  })

  const tenantConfirmSlotMutation = useMutation({
    mutationFn: ({ id, confirm }: { id: string; confirm: boolean }) => maintenanceApi.tenantConfirmSlot(id, confirm),
    onSuccess: (_, variables) => {
      qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      showToast({ message: variables.confirm ? 'Đã xác nhận lịch sửa chữa!' : 'Đã từ chối lịch, KTV sẽ liên hệ sắp xếp lại', type: 'success' })
    },
    onError: (err: any) => {
      showToast({ message: err?.response?.data?.message ?? 'Lỗi xác nhận lịch', type: 'error' })
    },
  })

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files ?? [])
    if (files.length === 0) return

    const urls = files.map((file) => URL.createObjectURL(file))
    setImages((prev) => [...prev, ...files])
    setPreviewUrls((prev) => [...prev, ...urls])
  }

  function removeImage(index: number) {
    const url = previewUrls[index]
    if (url) URL.revokeObjectURL(url)
    setImages((prev) => prev.filter((_, idx) => idx !== index))
    setPreviewUrls((prev) => prev.filter((_, idx) => idx !== index))
  }

  function toggleSlot(slot: string) {
    setPreferredSlots((prev) =>
      prev.includes(slot) ? prev.filter((s) => s !== slot) : [...prev, slot]
    )
  }

  function handleSubmit(event: React.FormEvent) {
    event.preventDefault()
    if (!activeRoom) {
      setError('Bạn chưa có phòng đang thuê để gửi yêu cầu')
      return
    }
    if (!title.trim()) {
      setError('Tiêu đề không được để trống')
      return
    }
    setError('')
    createMutation.mutate()
  }

  return (
    <Layout title="Bảo trì">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-fg">Yêu cầu bảo trì</h1>
            <p className="text-sm text-fg-muted">Gửi và theo dõi tiến độ sửa chữa cho phòng của bạn</p>
          </div>
          <Button variant="primary" onClick={() => { setShowCreate(true); setError('') }}>
            + Tạo yêu cầu mới
          </Button>
        </div>

        {/* Modal Tạo Yêu Cầu */}
        {showCreate && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
            <Card className="max-h-[90vh] w-full max-w-lg overflow-y-auto animate-scale-in p-6">
              <div className="mb-4 flex items-center justify-between border-b border-border/60 pb-3">
                <h2 className="text-lg font-semibold text-fg">Tạo yêu cầu bảo trì</h2>
                <button
                  onClick={() => {
                    setShowCreate(false)
                    resetForm()
                  }}
                  className="text-fg-subtle transition-colors hover:text-fg"
                >
                  <X size={18} />
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                {activeRoom && (
                  <div className="rounded-xl border border-border/80 bg-sidebar/60 px-3.5 py-2.5">
                    <p className="text-xs font-medium uppercase tracking-wide text-fg-subtle">Phòng của bạn</p>
                    <p className="mt-1 text-sm font-semibold text-fg">
                      Phòng {activeRoom.roomNumber} - {getRoomPropertyName(activeRoom)}
                    </p>
                  </div>
                )}

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="mb-1 block text-xs font-medium text-fg">Mức độ ưu tiên</label>
                    <select
                      value={priority}
                      onChange={(e) => setPriority(e.target.value as any)}
                      className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    >
                      <option value="NORMAL">Bình thường</option>
                      <option value="HIGH">Ưu tiên cao</option>
                      <option value="URGENT">Khẩn cấp (!)</option>
                    </select>
                  </div>

                  <div>
                    <label className="mb-1 block text-xs font-medium text-fg">Danh mục sự cố</label>
                    <select
                      value={category}
                      onChange={(e) => setCategory(e.target.value as any)}
                      className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    >
                      <option value="ELECTRIC">Điện</option>
                      <option value="PLUMBING">Nước / Đường ống</option>
                      <option value="AIR_CONDITIONER">Điều hòa</option>
                      <option value="FURNITURE">Nội thất / Cửa</option>
                      <option value="OTHER">Khác</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">
                    Tiêu đề sự cố <span className="text-error">*</span>
                  </label>
                  <input
                    type="text"
                    value={title}
                    onChange={(event) => setTitle(event.target.value)}
                    required
                    className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    placeholder="VD: Điều hòa không lạnh, vòi nước bị rò..."
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Mô tả chi tiết</label>
                  <textarea
                    rows={3}
                    value={description}
                    onChange={(event) => setDescription(event.target.value)}
                    className="w-full resize-none rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    placeholder="Mô tả cụ thể hiện tượng, xảy ra từ lúc nào, ở khu vực nào..."
                  />
                </div>

                <div>
                  <label className="mb-1.5 block text-sm font-medium text-fg">Khung giờ bạn có ở nhà (tùy chọn)</label>
                  <div className="grid grid-cols-2 gap-2">
                    {AVAILABLE_SLOTS.map((slot) => {
                      const selected = preferredSlots.includes(slot)
                      return (
                        <button
                          key={slot}
                          type="button"
                          onClick={() => toggleSlot(slot)}
                          className={`flex items-center gap-2 rounded-xl border px-3 py-2 text-left text-xs transition-colors ${
                            selected
                              ? 'border-accent bg-accent/10 font-medium text-accent'
                              : 'border-border/80 bg-surface text-fg-muted hover:border-border'
                          }`}
                        >
                          <Clock size={14} className={selected ? 'text-accent' : 'text-fg-subtle'} />
                          {slot}
                        </button>
                      )
                    })}
                  </div>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Hình ảnh hiện trường</label>
                  <input ref={fileRef} type="file" accept="image/*" multiple onChange={handleFileChange} className="hidden" />
                  <button
                    type="button"
                    onClick={() => fileRef.current?.click()}
                    className="flex items-center gap-2 rounded-xl border border-border/80 px-4 py-2 text-sm text-fg-muted transition-colors hover:bg-sidebar"
                  >
                    <Camera size={16} />
                    Chọn hình ảnh đính kèm
                  </button>

                  {previewUrls.length > 0 && (
                    <div className="mt-2 flex flex-wrap gap-2">
                      {previewUrls.map((url, index) => (
                        <div key={url} className="relative">
                          <img src={url} alt="" className="h-20 w-20 rounded-xl border border-border/80 object-cover" />
                          <button
                            type="button"
                            onClick={() => removeImage(index)}
                            className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-error text-error-fg"
                          >
                            <X size={10} />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Video minh chứng (tùy chọn)</label>
                  <label className="flex cursor-pointer items-center gap-2 rounded-xl border border-border/80 px-4 py-2 text-sm text-fg-muted transition-colors hover:bg-sidebar">
                    <Video size={16} />
                    <span>{video ? video.name : 'Chọn video đính kèm'}</span>
                    <input type="file" accept="video/*" className="hidden" onChange={(event) => setVideo(event.target.files?.[0] ?? null)} />
                  </label>
                </div>

                {error && <p className="text-sm text-error">{error}</p>}

                <div className="flex gap-3 pt-3 border-t border-border/60">
                  <Button
                    type="button"
                    variant="outline"
                    className="flex-1"
                    onClick={() => {
                      setShowCreate(false)
                      resetForm()
                    }}
                  >
                    Hủy
                  </Button>
                  <Button type="submit" variant="primary" className="flex-1" disabled={createMutation.isPending || !activeRoom}>
                    {createMutation.isPending ? 'Đang gửi...' : 'Gửi yêu cầu'}
                  </Button>
                </div>
              </form>
            </Card>
          </div>
        )}

        {/* Modal Khiếu nại / Phản hồi */}
        {complainModalId && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
            <Card className="w-full max-w-md animate-scale-in p-6">
              <div className="mb-4 flex items-center justify-between border-b border-border/60 pb-3">
                <div className="flex items-center gap-2 text-error font-semibold">
                  <ShieldAlert size={18} />
                  <span>Gửi phản hồi / Khiếu nại chất lượng</span>
                </div>
                <button onClick={() => setComplainModalId(null)} className="text-fg-subtle hover:text-fg">
                  <X size={18} />
                </button>
              </div>

              <p className="text-xs text-fg-muted mb-3">
                Nếu chất lượng sửa chữa chưa đạt yêu cầu hoặc có vấn đề phát sinh, hãy cho Kỹ thuật viên và Quản lý biết lý do để xử lý lại.
              </p>

              <textarea
                rows={3}
                value={complainReason}
                onChange={(e) => setComplainReason(e.target.value)}
                placeholder="Nhập lý do chưa hài lòng / cần khắc phục lại..."
                className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent mb-4"
              />

              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setComplainModalId(null)}>
                  Hủy
                </Button>
                <Button
                  variant="primary"
                  disabled={!complainReason.trim() || complainMutation.isPending}
                  onClick={() => complainMutation.mutate({ id: complainModalId, reason: complainReason })}
                  className="bg-error hover:bg-error/90 text-error-fg"
                >
                  {complainMutation.isPending ? 'Đang gửi...' : 'Xác nhận khiếu nại'}
                </Button>
              </div>
            </Card>
          </div>
        )}

        {/* Danh sách Yêu cầu */}
        {isLoading ? (
          <ListSkeleton items={4} />
        ) : (
          <div className="space-y-4">
            {requests.map((request) => (
              <Card key={request.id} className="overflow-hidden border border-border/80 transition-shadow hover:shadow-md">
                <CardContent className="p-5">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1 space-y-2">
                      <div className="flex flex-wrap items-center gap-2">
                        {request.ticketCode && (
                          <span className="rounded-lg bg-sidebar px-2 py-0.5 text-xs font-mono font-semibold text-fg">
                            #{request.ticketCode}
                          </span>
                        )}
                        <h3 className="text-base font-semibold text-fg">{request.title}</h3>
                        <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${priorityColor(request.priority)}`}>
                          {priorityLabel(request.priority)}
                        </span>
                        {request.category && (
                          <span className="inline-flex items-center rounded-full bg-accent/10 px-2 py-0.5 text-[11px] font-medium text-accent">
                            {categoryLabel(request.category)}
                          </span>
                        )}
                      </div>

                      <p className="text-xs text-fg-muted font-medium">
                        Phòng: {request.room?.roomNumber || '-'} • Ngày gửi: {formatDate(request.createdAt)}
                        {request.assignedTo && ` • KTV phụ trách: ${request.assignedTo.fullName}`}
                      </p>

                      {request.description && (
                        <p className="text-sm text-fg-muted bg-sidebar/50 rounded-xl p-3 border border-border/40">
                          {request.description}
                        </p>
                      )}

                      {/* Khung giờ ưa thích / Lịch KTV đề xuất */}
                      {(request.preferredTimeSlots?.length || 0) > 0 && !request.confirmedTimeSlot && (
                        <div className="flex items-center gap-2 text-xs text-fg-subtle">
                          <Clock size={13} />
                          <span>Khung giờ mong muốn: {(request.preferredTimeSlots || []).join(', ')}</span>
                        </div>
                      )}

                      {request.confirmedTimeSlot && (
                        <div className="mt-2 flex items-center justify-between rounded-xl border border-accent/30 bg-accent/5 p-3 text-xs">
                          <div className="flex items-center gap-2 text-accent font-medium">
                            <Clock size={15} />
                            <span>Lịch hẹn KTV: <b>{request.confirmedTimeSlot}</b></span>
                          </div>
                          {request.confirmSlotByTenant ? (
                            <span className="inline-flex items-center gap-1 rounded-full bg-success/15 px-2 py-0.5 text-[11px] font-semibold text-success">
                              <CheckCircle size={12} /> Bạn đã xác nhận
                            </span>
                          ) : (
                            <div className="flex gap-2">
                              <button
                                onClick={() => tenantConfirmSlotMutation.mutate({ id: request.id, confirm: true })}
                                className="rounded-lg bg-accent px-2.5 py-1 font-semibold text-accent-fg hover:bg-accent-hover"
                              >
                                Xác nhận lịch
                              </button>
                              <button
                                onClick={() => tenantConfirmSlotMutation.mutate({ id: request.id, confirm: false })}
                                className="rounded-lg border border-border px-2.5 py-1 font-medium text-fg hover:bg-sidebar"
                              >
                                Báo bận
                              </button>
                            </div>
                          )}
                        </div>
                      )}

                      {/* Khiếu nại status */}
                      {request.isComplained && (
                        <div className="mt-2 flex items-start gap-2 rounded-xl border border-error/30 bg-error/5 p-3 text-xs text-error">
                          <AlertTriangle size={15} className="shrink-0 mt-0.5" />
                          <div>
                            <p className="font-semibold">Đang phản hồi / Khiếu nại chất lượng:</p>
                            <p className="mt-0.5 text-error/90">{request.complainReason || 'Chưa hài lòng với kết quả sửa chữa.'}</p>
                          </div>
                        </div>
                      )}

                      {/* Hình ảnh */}
                      {request.images && request.images.length > 0 && (
                        <div className="pt-1">
                          <p className="mb-1.5 text-xs text-fg-subtle">Ảnh đính kèm ban đầu:</p>
                          <div className="flex flex-wrap gap-2">
                            {request.images.map((image) => (
                              <a key={image} href={image} target="_blank" rel="noreferrer">
                                <img src={image} alt="" className="h-16 w-16 rounded-xl border border-border/80 object-cover transition-transform hover:scale-105" />
                              </a>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Ảnh hoàn thành từ KTV */}
                      {request.completionImages && request.completionImages.length > 0 && (
                        <div className="pt-2">
                          <p className="mb-1.5 text-xs font-semibold text-success">Ảnh nghiệm thu từ KTV:</p>
                          <div className="flex flex-wrap gap-2">
                            {request.completionImages.map((image) => (
                              <a key={image} href={image} target="_blank" rel="noreferrer">
                                <img src={image} alt="" className="h-16 w-16 rounded-xl border border-success/40 object-cover transition-transform hover:scale-105" />
                              </a>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>

                    <div className="flex flex-col items-end gap-3 shrink-0">
                      <Badge status={request.status} />

                      {/* Thanh toán chi phí vật tư */}
                      {request.status === 'PENDING_PAYMENT' && (
                        <div className="flex flex-col items-end gap-2 rounded-xl border border-amber-500/40 bg-amber-500/10 p-3 text-right">
                          <p className="text-xs font-semibold text-amber-700 dark:text-amber-300">Chi phí vật tư thay thế</p>
                          <p className="text-base font-bold text-amber-800 dark:text-amber-200">
                            {formatCurrency(Number(request.materialCost || 0))}
                          </p>
                          <Button
                            variant="primary"
                            size="sm"
                            disabled={payMaterialMutation.isPending}
                            onClick={() => payMaterialMutation.mutate(request.id)}
                            className="flex items-center gap-1.5 bg-amber-600 hover:bg-amber-700 text-white shadow-sm"
                          >
                            <CreditCard size={14} />
                            Thanh toán vật tư
                          </Button>
                        </div>
                      )}

                      {/* Nghiệm thu & Khiếu nại */}
                      {request.status === 'PENDING_REVIEW' && (
                        <div className="flex flex-col items-end gap-2 pt-1">
                          <div className="text-xs text-right text-fg-muted max-w-[200px]">
                            KTV đã hoàn tất sửa chữa. Vui lòng kiểm tra và nghiệm thu (phiếu sẽ tự động xác nhận sau 48h).
                          </div>
                          <div className="flex gap-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => { setComplainModalId(request.id); setComplainReason('') }}
                              className="text-error border-error/40 hover:bg-error/10"
                            >
                              Khiếu nại / Khắc phục lại
                            </Button>
                            <Button
                              variant="primary"
                              size="sm"
                              disabled={resolveMutation.isPending}
                              onClick={() => resolveMutation.mutate(request.id)}
                              className="flex items-center gap-1.5 bg-success hover:bg-success/90 text-success-fg font-semibold shadow-sm"
                            >
                              <CheckCircle size={14} />
                              Xác nhận hoàn thành
                            </Button>
                          </div>
                        </div>
                      )}

                      {/* Đánh giá chất lượng dịch vụ khi hoàn thành */}
                      {(request.status === 'COMPLETED' || request.status === 'DONE') && (
                        <div className="flex flex-col items-end gap-2 pt-1">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              setReviewModalId(request.id)
                              setRatingStars(5)
                              setReviewComment('')
                            }}
                            className="flex items-center gap-1.5 border-amber-400 text-amber-700 hover:bg-amber-50 dark:border-amber-600 dark:text-amber-300 shadow-sm"
                          >
                            <Star size={14} className="fill-amber-500 text-amber-500" />
                            Đánh giá chất lượng KTV
                          </Button>
                        </div>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}

            {requests.length === 0 && (
              <div className="flex flex-col items-center justify-center py-12 rounded-2xl border border-dashed border-border text-center">
                <CheckCircle size={40} className="text-fg-subtle/50 mb-3" />
                <p className="font-medium text-fg">Chưa có yêu cầu bảo trì nào</p>
                <p className="text-xs text-fg-muted mt-1">Phòng của bạn đang hoạt động ổn định.</p>
              </div>
            )}
          </div>
        )}

        {/* Review Modal */}
        {reviewModalId && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 animate-fade-in">
            <Card className="w-full max-w-md rounded-2xl bg-surface p-6 shadow-xl border border-border space-y-4">
              <div className="flex items-center justify-between border-b border-border pb-3">
                <h3 className="text-lg font-semibold text-fg flex items-center gap-2">
                  <Star className="w-5 h-5 fill-amber-500 text-amber-500" />
                  Đánh Giá Chất Lượng Dịch Vụ
                </h3>
                <button
                  onClick={() => setReviewModalId(null)}
                  className="text-fg-subtle hover:text-fg transition-colors p-1"
                >
                  <X size={18} />
                </button>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-fg mb-2">Mức độ hài lòng của bạn</label>
                  <div className="flex items-center gap-2">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <button
                        key={star}
                        type="button"
                        onClick={() => setRatingStars(star)}
                        className="p-1 transition-transform hover:scale-110 focus:outline-none"
                      >
                        <Star
                          size={28}
                          className={star <= ratingStars ? 'fill-amber-500 text-amber-500' : 'text-gray-300 dark:text-gray-600'}
                        />
                      </button>
                    ))}
                    <span className="ml-2 text-sm font-bold text-amber-600">
                      {ratingStars} / 5 sao
                    </span>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-fg mb-1">Nhận xét chi tiết (tùy chọn)</label>
                  <textarea
                    rows={3}
                    value={reviewComment}
                    onChange={(e) => setReviewComment(e.target.value)}
                    placeholder="Hãy chia sẻ nhận xét của bạn về thái độ phục vụ và chất lượng sửa chữa của kỹ thuật viên..."
                    className="w-full rounded-xl border border-border bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                  />
                </div>

                <div className="flex justify-end gap-2 pt-2">
                  <Button
                    variant="outline"
                    onClick={() => setReviewModalId(null)}
                    disabled={reviewMutation.isPending}
                    className="rounded-xl"
                  >
                    Hủy bỏ
                  </Button>
                  <Button
                    onClick={() => reviewMutation.mutate({ id: reviewModalId, stars: ratingStars, comment: reviewComment })}
                    disabled={reviewMutation.isPending}
                    className="bg-amber-600 hover:bg-amber-700 text-white rounded-xl shadow-sm"
                  >
                    {reviewMutation.isPending ? 'Đang gửi...' : 'Gửi đánh giá'}
                  </Button>
                </div>
              </div>
            </Card>
          </div>
        )}
      </div>
    </Layout>
  )
}
