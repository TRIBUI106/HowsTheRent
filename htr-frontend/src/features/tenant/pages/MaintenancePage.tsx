import { useRef, useState } from 'react'
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
  const activeRoom = activeContracts[0]?.room

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
    onError: (e: any) => setError(e?.response?.data?.message ?? 'Lá»—i khi táº¡o yÃªu cáº§u'),
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
    if (!activeRoom) {
      setError('Báº¡n chÆ°a cÃ³ phÃ²ng Ä‘ang thuÃª Ä‘á»ƒ gá»­i yÃªu cáº§u')
      return
    }
    if (!title.trim()) {
      setError('TiÃªu Ä‘á» khÃ´ng Ä‘Æ°á»£c Ä‘á»ƒ trá»‘ng')
      return
    }
    setError('')
    createMutation.mutate()
  }

  return (
    <Layout title="Báº£o trÃ¬">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-fg">YÃªu cáº§u báº£o trÃ¬</h1>
          <Button variant="primary" onClick={() => { setShowCreate(true); setError('') }}>
            + Táº¡o yÃªu cáº§u
          </Button>
        </div>

        {showCreate && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <Card className="mx-4 w-full max-w-md p-6 animate-scale-in">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-fg">Táº¡o yÃªu cáº§u báº£o trÃ¬</h2>
                <button onClick={() => setShowCreate(false)} className="text-fg-subtle transition-colors hover:text-fg">
                  <X size={18} />
                </button>
              </div>
              <form onSubmit={handleSubmit} className="space-y-4">
                {activeRoom && (
                  <div className="rounded-xl border border-border/80 bg-sidebar/60 px-3 py-2.5">
                    <p className="text-xs font-medium uppercase tracking-wide text-fg-subtle">PhÃ²ng gá»­i yÃªu cáº§u</p>
                    <p className="mt-1 text-sm text-fg">{activeRoom.roomNumber} - {getRoomPropertyName(activeRoom)}</p>
                  </div>
                )}
                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">TiÃªu Ä‘á» <span className="text-error">*</span></label>
                  <input
                    type="text"
                    value={title}
                    onChange={e => setTitle(e.target.value)}
                    required
                    className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    placeholder="VD: BÆ¡m nÆ°á»›c bá»‹ rÃ²"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">MÃ´ táº£</label>
                  <textarea
                    rows={3}
                    value={description}
                    onChange={e => setDescription(e.target.value)}
                    className="w-full resize-none rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    placeholder="MÃ´ táº£ chi tiáº¿t váº¥n Ä‘á»..."
                  />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">HÃ¬nh áº£nh</label>
                  <input ref={fileRef} type="file" accept="image/*" multiple onChange={handleFileChange} className="hidden" />
                  <button
                    type="button"
                    onClick={() => fileRef.current?.click()}
                    className="flex items-center gap-2 rounded-xl border border-border/80 px-4 py-2 text-sm text-fg-muted transition-colors hover:bg-sidebar"
                  >
                    <Camera size={16} /> Chá»n hÃ¬nh áº£nh
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
                    Há»§y
                  </Button>
                  <Button type="submit" variant="primary" className="flex-1" disabled={createMutation.isPending || !activeRoom}>
                    {createMutation.isPending ? 'Äang gá»­i...' : 'Gá»­i yÃªu cáº§u'}
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
                  <p className="mt-3 text-xs text-fg-subtle">NgÃ y táº¡o: {formatDate(req.createdAt)}</p>
                </CardContent>
              </Card>
            ))}
            {requests.length === 0 && <p className="py-8 text-center text-fg-subtle">ChÆ°a cÃ³ yÃªu cáº§u báº£o trÃ¬</p>}
          </div>
        )}
      </div>
    </Layout>
  )
}
