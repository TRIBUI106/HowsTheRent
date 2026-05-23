import { useState, useRef } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import type { MaintenanceRequest } from '@/types'
import { Camera, X } from 'lucide-react'

export default function TenantMaintenancePage() {
  const qc = useQueryClient()
  const [showCreate, setShowCreate] = useState(false)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [images, setImages] = useState<File[]>([])
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const [error, setError] = useState('')
  const fileRef = useRef<HTMLInputElement>(null)

  const { data: requests, isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tenant-maintenance'],
    queryFn: () => api.get('/maintenance/mine').then(r => r.data),
  })

  const createMutation = useMutation({
    mutationFn: () => {
      const form = new FormData()
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
      setImages([])
      setPreviewUrls([])
      setError('')
    },
    onError: (e: any) => setError(e?.response?.data?.message ?? 'Lỗi khi tạo yêu cầu'),
  })

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? [])
    setImages(prev => [...prev, ...files])
    files.forEach(f => {
      const reader = new FileReader()
      reader.onloadend = () => setPreviewUrls(prev => [...prev, reader.result as string])
      reader.readAsDataURL(f)
    })
  }

  function removeImage(idx: number) {
    setImages(prev => prev.filter((_, i) => i !== idx))
    setPreviewUrls(prev => prev.filter((_, i) => i !== idx))
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!title.trim()) { setError('Tiêu đề không được để trống'); return }
    setError('')
    createMutation.mutate()
  }

  return (
    <Layout title="Bảo trì">
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-fg">Yêu cầu bảo trì</h1>
          <Button variant="primary" onClick={() => { setShowCreate(true); setError('') }}>
            + Tạo yêu cầu
          </Button>
        </div>

        {showCreate && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <Card className="w-full max-w-md mx-4 p-6 animate-scale-in">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-lg font-semibold text-fg">Tạo yêu cầu bảo trì</h2>
                <button onClick={() => setShowCreate(false)} className="text-fg-subtle hover:text-fg transition-colors">
                  <X size={18} />
                </button>
              </div>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-fg mb-1">Tiêu đề <span className="text-error">*</span></label>
                  <input type="text" value={title} onChange={e => setTitle(e.target.value)} required
                    className="w-full border border-border/80 rounded-xl px-3 py-2 text-sm bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    placeholder="VD: Bom nuoc bi ro" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-fg mb-1">Mô tả</label>
                  <textarea rows={3} value={description} onChange={e => setDescription(e.target.value)}
                    className="w-full border border-border/80 rounded-xl px-3 py-2 text-sm bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent resize-none"
                    placeholder="Mô tả chi tiết vấn đề..." />
                </div>
                <div>
                  <label className="block text-sm font-medium text-fg mb-1">Hình ảnh</label>
                  <input ref={fileRef} type="file" accept="image/*" multiple onChange={handleFileChange}
                    className="hidden" />
                  <button type="button" onClick={() => fileRef.current?.click()}
                    className="flex items-center gap-2 px-4 py-2 border border-border/80 rounded-xl text-sm text-fg-muted hover:bg-sidebar transition-colors">
                    <Camera size={16} /> Chọn hình ảnh
                  </button>
                  {previewUrls.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-2">
                      {previewUrls.map((url, i) => (
                        <div key={i} className="relative">
                          <img src={url} alt="" className="w-20 h-20 object-cover rounded-xl border border-border/80" />
                          <button type="button" onClick={() => removeImage(i)}
                            className="absolute -top-1 -right-1 w-5 h-5 bg-error text-error-fg rounded-full flex items-center justify-center text-xs">
                            <X size={10} />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
                {error && <p className="text-sm text-error">{error}</p>}
                <div className="flex gap-3 pt-2">
                  <Button type="button" variant="outline" className="flex-1" onClick={() => setShowCreate(false)}>Huỷ</Button>
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
            {requests?.map(req => (
              <Card key={req.id}>
                <CardContent className="p-4">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <p className="font-medium text-fg">{req.title}</p>
                      <p className="text-sm text-fg-muted mt-1">{req.room?.roomNumber}</p>
                      {req.description && <p className="text-sm text-fg-muted mt-2">{req.description}</p>}
                      {req.images && req.images.length > 0 && (
                        <div className="flex flex-wrap gap-2 mt-2">
                          {req.images.map((img, i) => (
                            <img key={i} src={img} alt="" className="w-16 h-16 object-cover rounded-xl border border-border/80" />
                          ))}
                        </div>
                      )}
                    </div>
                    <Badge status={req.status} />
                  </div>
                  <p className="text-xs text-fg-subtle mt-3">Ngày tạo: {formatDate(req.createdAt)}</p>
                </CardContent>
              </Card>
            ))}
            {requests?.length === 0 && <p className="text-center text-fg-subtle py-8">Chưa có yêu cầu bảo trì</p>}
          </div>
        )}
      </div>
    </Layout>
  )
}
