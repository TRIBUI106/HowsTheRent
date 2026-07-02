import { useRef, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Camera, X } from 'lucide-react'
import api from '@/lib/api'
import { extractPageContent, getRoomPropertyName, normalizeContract, normalizeMaintenanceRequest } from '@/lib/apiMappers'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { Contract, MaintenanceRequest } from '@/types'

export default function TenantMaintenancePage() {
  const qc = useQueryClient()
  const fileRef = useRef<HTMLInputElement>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [images, setImages] = useState<File[]>([])
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const [error, setError] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['tenant-maintenance'],
    queryFn: () => api.get('/maintenance/mine').then((r) => r.data),
  })

  const { data: contractsData } = useQuery({
    queryKey: ['tenant-contracts'],
    queryFn: () => api.get('/contracts/mine').then((r) => r.data),
  })

  const requests: MaintenanceRequest[] = extractPageContent<any>(data).map(normalizeMaintenanceRequest)
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
    setImages([])
    clearPreviews()
    setError('')
  }

  const createMutation = useMutation({
    mutationFn: () => {
      const form = new FormData()
      form.append('title', title.trim())
      if (description.trim()) form.append('description', description.trim())
      images.forEach((image) => form.append('images', image))
      return api.post('/maintenance/with-images', form)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
      setShowCreate(false)
      resetForm()
      showToast({ message: 'Đã gửi yêu cầu bảo trì', type: 'success' })
    },
    onError: (error: any) => {
      const message = error?.response?.data?.message ?? 'Lỗi khi tạo yêu cầu'
      setError(message)
      showToast({ message, type: 'error' })
    },
  })

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files ?? [])
    if (files.length === 0) return

    const urls = files.map((file) => URL.createObjectURL(file))
    setImages((previous) => [...previous, ...files])
    setPreviewUrls((previous) => [...previous, ...urls])
  }

  function removeImage(index: number) {
    const url = previewUrls[index]
    if (url) URL.revokeObjectURL(url)
    setImages((previous) => previous.filter((_, imageIndex) => imageIndex !== index))
    setPreviewUrls((previous) => previous.filter((_, urlIndex) => urlIndex !== index))
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
          <h1 className="text-2xl font-bold text-fg">Yêu cầu bảo trì</h1>
          <Button variant="primary" onClick={() => { setShowCreate(true); setError('') }}>
            + Tạo yêu cầu
          </Button>
        </div>

        {showCreate && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <Card className="mx-4 w-full max-w-md animate-scale-in p-6">
              <div className="mb-4 flex items-center justify-between">
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
                  <div className="rounded-xl border border-border/80 bg-sidebar/60 px-3 py-2.5">
                    <p className="text-xs font-medium uppercase tracking-wide text-fg-subtle">Phòng gửi yêu cầu</p>
                    <p className="mt-1 text-sm text-fg">
                      {activeRoom.roomNumber} - {getRoomPropertyName(activeRoom)}
                    </p>
                  </div>
                )}

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">
                    Tiêu đề <span className="text-error">*</span>
                  </label>
                  <input
                    type="text"
                    value={title}
                    onChange={(event) => setTitle(event.target.value)}
                    required
                    className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    placeholder="VD: Bơm nước bị rò"
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Mô tả</label>
                  <textarea
                    rows={3}
                    value={description}
                    onChange={(event) => setDescription(event.target.value)}
                    className="w-full resize-none rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    placeholder="Mô tả chi tiết vấn đề..."
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Hình ảnh</label>
                  <input ref={fileRef} type="file" accept="image/*" multiple onChange={handleFileChange} className="hidden" />
                  <button
                    type="button"
                    onClick={() => fileRef.current?.click()}
                    className="flex items-center gap-2 rounded-xl border border-border/80 px-4 py-2 text-sm text-fg-muted transition-colors hover:bg-sidebar"
                  >
                    <Camera size={16} />
                    Chọn hình ảnh
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

                {error && <p className="text-sm text-error">{error}</p>}

                <div className="flex gap-3 pt-2">
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

        {isLoading ? (
          <ListSkeleton items={4} />
        ) : (
          <div className="space-y-4">
            {requests.map((request) => (
              <Card key={request.id}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <p className="font-medium text-fg">{request.title}</p>
                      <p className="mt-1 text-sm text-fg-muted">{request.room?.roomNumber}</p>
                      {request.description && <p className="mt-2 text-sm text-fg-muted">{request.description}</p>}
                      {request.images.length > 0 && (
                        <div className="mt-2 flex flex-wrap gap-2">
                          {request.images.map((image) => (
                            <img key={image} src={image} alt="" className="h-16 w-16 rounded-xl border border-border/80 object-cover" />
                          ))}
                        </div>
                      )}
                    </div>
                    <Badge status={request.status} />
                  </div>
                  <p className="mt-3 text-xs text-fg-subtle">Ngày tạo: {formatDate(request.createdAt)}</p>
                </CardContent>
              </Card>
            ))}

            {requests.length === 0 && (
              <p className="py-8 text-center text-fg-subtle">Chưa có yêu cầu bảo trì</p>
            )}
          </div>
        )}
      </div>
    </Layout>
  )
}
