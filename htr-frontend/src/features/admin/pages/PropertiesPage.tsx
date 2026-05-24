import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Dialog } from '@/components/ui/dialog'
import { propertyTypeApi } from '@/api'
import { formatDate } from '@/lib/utils'
import type { Property, PropertyType } from '@/types'

const emptyForm = { name: '', address: '', propertyTypeId: '', description: '' }
const emptyTypeForm = { code: '', name: '', description: '' }

export default function PropertiesPage() {
  const qc = useQueryClient()
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [deletingProperty, setDeletingProperty] = useState<Property | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [showTypeForm, setShowTypeForm] = useState(false)
  const [editingTypeId, setEditingTypeId] = useState<string | null>(null)
  const [deletingType, setDeletingType] = useState<PropertyType | null>(null)
  const [typeForm, setTypeForm] = useState(emptyTypeForm)

  const { data: properties, isLoading } = useQuery<Property[]>({
    queryKey: ['properties'],
    queryFn: () => api.get('/properties').then(r => r.data),
  })

  const { data: propertyTypes = [] } = useQuery<PropertyType[]>({
    queryKey: ['property-types'],
    queryFn: () => propertyTypeApi.list(),
  })

  const activePropertyTypes = propertyTypes.filter(t => t.active)

  const resetForm = () => {
    setShowForm(false)
    setEditingId(null)
    setForm(emptyForm)
  }

  const resetTypeForm = () => {
    setShowTypeForm(false)
    setEditingTypeId(null)
    setTypeForm(emptyTypeForm)
  }

  const save = useMutation({
    mutationFn: (d: typeof form) => editingId ? api.put(`/properties/${editingId}`, d) : api.post('/properties', d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['properties'] }); resetForm() },
  })

  const saveType = useMutation({
    mutationFn: (d: typeof typeForm) => editingTypeId ? propertyTypeApi.update(editingTypeId, d) : propertyTypeApi.create(d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['property-types'] }); resetTypeForm() },
  })

  const toggleTypeActive = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) => propertyTypeApi.updateActive(id, active),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['property-types'] }),
  })

  const removeType = useMutation({
    mutationFn: (id: string) => propertyTypeApi.remove(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['property-types'] })
      setDeletingType(null)
    },
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
    setForm({ ...emptyForm, propertyTypeId: activePropertyTypes[0]?.id ?? '' })
    setShowForm(true)
  }

  function startEdit(property: Property) {
    setEditingId(property.id)
    setForm({
      name: property.name,
      address: property.address,
      propertyTypeId: property.propertyTypeId,
      description: property.description || '',
    })
    setShowForm(true)
  }

  function startCreateType() {
    if (showTypeForm && !editingTypeId) return resetTypeForm()
    setEditingTypeId(null)
    setTypeForm(emptyTypeForm)
    setShowTypeForm(true)
  }

  function startEditType(type: PropertyType) {
    setEditingTypeId(type.id)
    setTypeForm({ code: type.code, name: type.name, description: type.description || '' })
    setShowTypeForm(true)
  }

  return (
    <Layout title="Tài sản">
      <div className="flex justify-between items-center mb-6">
        <p className="text-sm text-fg-muted">Quản lý tài sản</p>
        <Button onClick={startCreate}>{showForm && !editingId ? 'Đóng' : '+ Thêm tài sản'}</Button>
      </div>

      <Card className="mb-6">
        <CardHeader>
          <div className="flex items-center justify-between gap-3">
            <span>Loại tài sản</span>
            <Button size="sm" onClick={startCreateType}>{showTypeForm && !editingTypeId ? 'Đóng' : '+ Thêm loại'}</Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {showTypeForm && (
            <form onSubmit={(e) => { e.preventDefault(); saveType.mutate(typeForm) }} className="grid grid-cols-1 md:grid-cols-4 gap-3">
              <Input label="Mã" value={typeForm.code} onChange={e => setTypeForm({ ...typeForm, code: e.target.value })} required />
              <Input label="Tên loại" value={typeForm.name} onChange={e => setTypeForm({ ...typeForm, name: e.target.value })} required />
              <Input label="Mô tả" value={typeForm.description} onChange={e => setTypeForm({ ...typeForm, description: e.target.value })} />
              <div className="flex items-end gap-2">
                <Button type="submit" loading={saveType.isPending}>{editingTypeId ? 'Lưu' : 'Tạo'}</Button>
                <Button type="button" variant="secondary" onClick={resetTypeForm}>Huỷ</Button>
              </div>
            </form>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {propertyTypes.map(type => (
              <div key={type.id} className="rounded-xl border border-border bg-sidebar p-3">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-medium text-fg">{type.name}</p>
                    <p className="text-xs text-fg-subtle mt-1">{type.code}</p>
                  </div>
                  <Badge status={type.active ? 'ACTIVE' : 'INACTIVE'} />
                </div>
                {type.description && <p className="text-sm text-fg-muted mt-2">{type.description}</p>}
                <div className="mt-3 flex gap-2 flex-wrap">
                  <Button type="button" variant="secondary" size="sm" onClick={() => startEditType(type)}>Sửa</Button>
                  <Button
                    type="button"
                    variant={type.active ? 'outline' : 'primary'}
                    size="sm"
                    onClick={() => toggleTypeActive.mutate({ id: type.id, active: !type.active })}
                    disabled={toggleTypeActive.isPending}
                  >
                    {type.active ? 'Vô hiệu hoá' : 'Kích hoạt'}
                  </Button>
                  <Button type="button" variant="danger" size="sm" onClick={() => setDeletingType(type)}>
                    Xoá
                  </Button>
                </div>
              </div>
            ))}
            {propertyTypes.length === 0 && <p className="text-sm text-fg-subtle">Chưa có loại tài sản</p>}
          </div>
        </CardContent>
      </Card>

      {showForm && (
        <Card className="mb-6">
          <CardHeader>{editingId ? 'Cập nhật tài sản' : 'Tạo tài sản mới'}</CardHeader>
          <CardContent>
            <form onSubmit={(e) => { e.preventDefault(); save.mutate(form) }} className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input label="Tên tài sản" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required />
              <Input label="Địa chỉ" value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} required />
              <div className="space-y-1">
                <label className="block text-sm font-medium text-fg">Loại</label>
                <select className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg" value={form.propertyTypeId} onChange={e => setForm({ ...form, propertyTypeId: e.target.value })} required>
                  <option value="" disabled>Chọn loại tài sản</option>
                  {activePropertyTypes.map(type => <option key={type.id} value={type.id}>{type.name}</option>)}
                </select>
              </div>
              <Input label="Mô tả" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
              <div className="md:col-span-2 flex gap-2">
                <Button type="submit" loading={save.isPending} disabled={!form.propertyTypeId}>{save.isPending ? 'Đang lưu...' : editingId ? 'Lưu thay đổi' : 'Tạo tài sản'}</Button>
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
                </div>
                <div className="mt-4 grid grid-cols-2 gap-3 rounded-xl border border-border bg-sidebar p-3 text-xs">
                  <div>
                    <p className="text-fg-subtle">Loại</p>
                    <p className="mt-1 font-medium text-fg">{p.propertyTypeName}</p>
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

      <Dialog open={!!deletingType} onClose={() => setDeletingType(null)} title="Xoá loại tài sản?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">
            Bạn sắp xoá loại tài sản <span className="font-semibold text-fg">{deletingType?.name}</span>. Hành động này không thể hoàn tác.
          </p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setDeletingType(null)}>Huỷ</Button>
            <Button type="button" variant="danger" loading={removeType.isPending} onClick={() => deletingType && removeType.mutate(deletingType.id)}>
              Xác nhận xoá
            </Button>
          </div>
        </div>
      </Dialog>
    </Layout>
  )
}
