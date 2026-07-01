import { useEffect, useRef, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import { extractPageContent, getRoomPropertyName, normalizeContract, normalizeMaintenanceRequest } from '@/lib/apiMappers'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import type { Contract, MaintenanceRequest } from '@/types'
import { Camera, X } from 'lucide-react'

export default function TenantMaintenancePage() {
  const qc = useQueryClient()
  const [showCreate, setShowCreate] = useState(false)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [roomId, setRoomId] = useState('')
  const [images, setImages] = useState<File[]>([])
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const [error, setError] = useState('')
  const fileRef = useRef<HTMLInputElement>(null)

  const { data, isLoading } = useQuery({
    queryKey: ['tenant-maintenance'],
    queryFn: () => api.get('/maintenance/mine').then(r => r.data),
  })

  const { data: contractsData } = useQuery({
    queryKey: ['tenant-contracts'],
    queryFn: () => api.get('/contracts/mine').then(r => r.data),
  })

  const requests: MaintenanceRequest[] = extractPageContent<any>(data).map(normalizeMaintenanceRequest)
  const activeContracts: Contract[] = extractPageContent<any>(contractsData)
    .map(normalizeContract)
    .filter(contract => contract.status === 'ACTIVE')

  useEffect(() => {
    if (!roomId && activeContracts.length === 1) {
      setRoomId(activeContracts[0].room.id)
    }
  }, [activeContracts, roomId])

  const createMutation = useMutation({
    mutationFn: () => {
      const form = new FormData()
      form.append('roomId', roomId)
      form.append('title', title)
      if (description) form.append('description', description)
      images.forEach(img => form.append('images', img))
      return api.post('/maintenance/with-images', form, { headers: { 'Content-Type': 'multipart/form-data' } })
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      setShowCreate(false)
      setTitle('')
      setDescription('')
      setRoomId(activeContracts.length === 1 ? activeContracts[0].room.id : '')
      setImages([])
      setPreviewUrls([])
      setError('')
    },
    onError: (e: any) => setError(e?.response?.data?.message ?? 'Lỗi khi tạo yêu cầu'),
  })

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? [])
    setImages(prev => [...prev, ...files])
    files.forEach(file => {
      const reader = new FileReader()
      reader.onloadend = () => setPreviewUrls(prev => [...prev, reader.result as string])
      reader.readAsDataURL(file)
    })
  }

  function removeImage(index: number) {
    setImages(prev => prev.filter((_, i) => i !== index))
    setPreviewUrls(prev => prev.filter((_, i) => i !== index))
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!roomId) {
      setError('Vui lòng chọn phòng')
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
            <Card className="mx-4 w-full max-w-md p-6 animate-scale-in">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-fg">Tạo yêu cầu bảo trì</h2>
                <button onClick={() => setShowCreate(false)} className="text-fg-subtle transition-colors hover:text-fg">
                  <X size={18} />
                </button>
              </div>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Phòng <span className="text-error">*</span></label>
                  <select
                    value={roomId}
                    onChange={e => setRoomId(e.target.value)}
                    required
                    className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                  >
                    <option value="">Chọn phòng</option>
                    {activeContracts.map(contract => (
                      <option key={contract.id} value={contract.room.id}>
                        {contract.room.roomNumber} - {getRoomPropertyName(contract.room)}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Tiêu đề <span className="text-error">*</span></label>
                  <input
                    type="text"
                    value={title}
                    onChange={e => setTitle(e.target.value)}
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
                    onChange={e => setDescription(e.target.value)}
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
                    <Camera size={16} /> Chọn hình ảnh
                  </button>
                  {previewUrls.length > 0 && (
                    <div className="mt-2 flex flex-wrap gap-2">
                      {previewUrls.map((url, index) => (
                        <div key={index} className="relative">
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
                  <Button type="button" variant="outline" className="flex-1" onClick={() => setShowCreate(false)}>
                    Hủy
                  </Button>
                  <Button type="submit" variant="primary" className="flex-1" disabled={createMutation.isPending}>
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
            {requests.map(req => (
              <Card key={req.id}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <p className="font-medium text-fg">{req.title}</p>
                      <p className="mt-1 text-sm text-fg-muted">{req.room?.roomNumber}</p>
                      {req.description && <p className="mt-2 text-sm text-fg-muted">{req.description}</p>}
                      {req.images.length > 0 && (
                        <div className="mt-2 flex flex-wrap gap-2">
                          {req.images.map((img, index) => (
                            <img key={index} src={img} alt="" className="h-16 w-16 rounded-xl border border-border/80 object-cover" />
                          ))}
                        </div>
                      )}
                    </div>
                    <Badge status={req.status} />
                  </div>
                  <p className="mt-3 text-xs text-fg-subtle">Ngày tạo: {formatDate(req.createdAt)}</p>
                </CardContent>
              </Card>
            ))}
            {requests.length === 0 && <p className="py-8 text-center text-fg-subtle">Chưa có yêu cầu bảo trì</p>}
          </div>
        )}
      </div>
    </Layout>
  )
}
