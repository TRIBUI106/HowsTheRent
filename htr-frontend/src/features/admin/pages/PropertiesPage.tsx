import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Dialog } from '@/components/ui/dialog'
import { formatDate } from '@/lib/utils'
import type { Property } from '@/types'

const emptyForm = { name: '', address: '', type: 'BOARDING_HOUSE', description: '' }
const propertyTypeLabels: Record<Property['type'], string> = {
  BOARDING_HOUSE: 'Nhà trọ',
  CONDO: 'Chung cư',
}

export default function PropertiesPage() {
  const qc = useQueryClient()
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [deletingProperty, setDeletingProperty] = useState<Property | null>(null)
  const [form, setForm] = useState(emptyForm)

  const { data: properties, isLoading } = useQuery<Property[]>({
    queryKey: ['properties'],
    queryFn: () => api.get('/properties/mine').then(r => r.data),
  })

  const resetForm = () => {
    setShowForm(false)
    setEditingId(null)
    setForm(emptyForm)
  }

  const save = useMutation({
    mutationFn: (d: typeof form) => editingId ? api.put(`/properties/${editingId}`, d) : api.post('/properties', d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['properties'] }); resetForm() },
  })

  const remove = useMutation({
    mutationFn: (id: string) => api.delete(`/properties/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] })
      setDeletingProperty(null)
    },
  })

  function startCreate() {
    if (showForm && !editingId) return resetForm()
    setEditingId(null)
    setForm(emptyForm)
    setShowForm(true)
  }

  function startEdit(property: Property) {
    setEditingId(property.id)
    setForm({
      name: property.name,
      address: property.address,
      type: property.type,
      description: property.description || '',
    })
    setShowForm(true)
  }

  return (
    <Layout title="Tài sản">
      <div className="flex justify-between items-center mb-6">
        <p className="text-sm text-fg-muted">Quản lý tài sản</p>
        <Button onClick={startCreate}>{showForm && !editingId ? 'Đóng' : '+ Thêm tài sản'}</Button>
      </div>

      {showForm && (
        <Card className="mb-6">
          <CardHeader>{editingId ? 'Cập nhật tài sản' : 'Tạo tài sản mới'}</CardHeader>
          <CardContent>
            <form onSubmit={(e) => { e.preventDefault(); save.mutate(form) }} className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input label="Tên tài sản" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required />
              <Input label="Địa chỉ" value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} required />
              <div className="space-y-1">
                <label className="block text-sm font-medium text-fg">Loại</label>
                <select className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg" value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>
                  <option value="BOARDING_HOUSE">Nhà trọ</option>
                  <option value="CONDO">Chung cư</option>
                </select>
              </div>
              <Input label="Mô tả" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
              <div className="md:col-span-2 flex gap-2">
                <Button type="submit" loading={save.isPending}>{save.isPending ? 'Đang lưu...' : editingId ? 'Lưu thay đổi' : 'Tạo tài sản'}</Button>
                <Button type="button" variant="secondary" onClick={resetForm}>Huỷ</Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-accent border-t-transparent rounded-full" />
        </div>
      ) : properties?.length === 0 ? (
        <div className="text-center py-12 text-fg-subtle">Chưa có tài sản nào</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {properties?.map(p => (
            <Card key={p.id}>
              <CardContent className="p-6">
                <div className="flex justify-between items-start gap-4">
                  <div>
                    <h3 className="font-semibold text-fg">{p.name}</h3>
                    <p className="text-sm text-fg-muted mt-1">{p.address}</p>
                  </div>
                  {/* <Badge status={p.type} /> */}
                </div>
                <div className="mt-4 grid grid-cols-2 gap-3 rounded-xl border border-border bg-sidebar p-3 text-xs">
                  <div>
                    <p className="text-fg-subtle">Loại</p>
                    <p className="mt-1 font-medium text-fg">{propertyTypeLabels[p.type]}</p>
                  </div>
                  <div>
                    <p className="text-fg-subtle">Trạng thái</p>
                    <p className="mt-1"><Badge status="ACTIVE" /></p>
                  </div>
                </div>
                {p.description && <p className="text-sm text-fg-muted mt-3">{p.description}</p>}
                <p className="text-xs text-fg-subtle mt-4">Tạo: {formatDate(p.createdAt)}</p>
                <div className="mt-5 flex gap-2">
                  <Button type="button" variant="secondary" size="sm" onClick={() => startEdit(p)}>Sửa</Button>
                  <Button type="button" variant="danger" size="sm" onClick={() => setDeletingProperty(p)}>Xoá</Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={!!deletingProperty} onClose={() => setDeletingProperty(null)} title="Xoá tài sản?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">
            Bạn sắp xoá tài sản <span className="font-semibold text-fg">{deletingProperty?.name}</span>. Các phòng và cấu hình liên quan cũng sẽ bị xoá. Hành động này không thể hoàn tác.
          </p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setDeletingProperty(null)}>Huỷ</Button>
            <Button type="button" variant="danger" loading={remove.isPending} onClick={() => deletingProperty && remove.mutate(deletingProperty.id)}>
              Xác nhận xoá
            </Button>
          </div>
        </div>
      </Dialog>
    </Layout>
  )
}
