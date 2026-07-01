import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Building2, FolderTree, Plus, Settings2, Tag } from 'lucide-react'
import { useState } from 'react'
import axios from 'axios'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Dialog } from '@/components/ui/dialog'
import { propertyTypeApi } from '@/api'
import { formatDate } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { Property, PropertyType } from '@/types'

function extractErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError(error)) {
    const msg = error.response?.data?.message
    if (typeof msg === 'string' && msg.trim()) return msg
  }
  return fallback
}

const emptyForm = { name: '', address: '', propertyTypeId: '', description: '' }
const emptyTypeForm = { code: '', name: '', description: '' }

export default function PropertiesPage() {
  const qc = useQueryClient()
  const [showForm, setShowForm] = useState(false)
  const [showTypePanel, setShowTypePanel] = useState(false)
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

  const propertyList = properties ?? []
  const activePropertyTypes = propertyTypes.filter(t => t.active)
  const inactivePropertyTypes = propertyTypes.filter(t => !t.active)
  const propertyCountByTypeId = propertyList.reduce<Record<string, number>>((acc, property) => {
    acc[property.propertyTypeId] = (acc[property.propertyTypeId] ?? 0) + 1
    return acc
  }, {})
  const isTypePanelVisible = showTypePanel || showTypeForm || !!editingTypeId || propertyTypes.length === 0

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
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] })
      showToast({ message: editingId ? 'Cập nhật tài sản thành công' : 'Tạo tài sản thành công', type: 'success' })
      resetForm()
    },
    onError: (error) => showToast({ message: extractErrorMessage(error, 'Lưu tài sản thất bại'), type: 'error' }),
  })

  const saveType = useMutation({
    mutationFn: (d: typeof typeForm) => editingTypeId ? propertyTypeApi.update(editingTypeId, d) : propertyTypeApi.create(d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['property-types'] })
      showToast({ message: editingTypeId ? 'Cập nhật loại tài sản thành công' : 'Tạo loại tài sản thành công', type: 'success' })
      resetTypeForm()
    },
    onError: (error) => showToast({ message: extractErrorMessage(error, 'Lưu loại tài sản thất bại'), type: 'error' }),
  })

  const toggleTypeActive = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) => propertyTypeApi.updateActive(id, active),
    onSuccess: (_data, variables) => {
      qc.invalidateQueries({ queryKey: ['property-types'] })
      showToast({ message: variables.active ? 'Đã kích hoạt loại tài sản' : 'Đã vô hiệu hóa loại tài sản', type: 'success' })
    },
    onError: (error) => showToast({ message: extractErrorMessage(error, 'Cập nhật trạng thái thất bại'), type: 'error' }),
  })

  const removeType = useMutation({
    mutationFn: (id: string) => propertyTypeApi.remove(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['property-types'] })
      setDeletingType(null)
      showToast({ message: 'Xóa loại tài sản thành công', type: 'success' })
    },
    onError: (error) => showToast({ message: extractErrorMessage(error, 'Xóa loại tài sản thất bại'), type: 'error' }),
  })

  const remove = useMutation({
    mutationFn: (id: string) => api.delete(`/properties/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] })
      setDeletingProperty(null)
      showToast({ message: 'Xóa tài sản thành công', type: 'success' })
    },
    onError: (error) => showToast({ message: extractErrorMessage(error, 'Xóa tài sản thất bại'), type: 'error' }),
  })

  function startCreate() {
    if (activePropertyTypes.length === 0) {
      setShowTypePanel(true)
      showToast({ message: 'Hãy tạo và kích hoạt ít nhất một loại tài sản trước khi thêm tài sản', type: 'info' })
      return
    }
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
    setShowTypePanel(true)
    if (showTypeForm && !editingTypeId) return resetTypeForm()
    setEditingTypeId(null)
    setTypeForm(emptyTypeForm)
    setShowTypeForm(true)
  }

  function startEditType(type: PropertyType) {
    setShowTypePanel(true)
    setEditingTypeId(type.id)
    setTypeForm({ code: type.code, name: type.name, description: type.description || '' })
    setShowTypeForm(true)
  }

  return (
    <Layout title="Tài sản">
      <section className="mb-6 rounded-[28px] border border-border/80 bg-surface px-6 py-6">
        <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
          <div className="max-w-2xl">
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-fg-subtle">Danh sách</p>
            <h2 className="mt-2 text-[28px] font-semibold tracking-[-0.02em] text-fg">
              Quản lý tài sản
            </h2>
            <p className="mt-2 text-sm leading-6 text-fg-muted">
              Mỗi tài sản là một địa chỉ cụ thể. Loại tài sản chỉ là danh mục dùng để phân nhóm khi tạo mới,
              không phải danh sách nhà hoặc dãy phòng riêng.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <Button type="button" variant="secondary" onClick={() => setShowTypePanel(v => !v)}>
              <Settings2 size={16} />
              {isTypePanelVisible ? 'Thu gọn loại tài sản' : 'Quản lý loại tài sản'}
            </Button>
            <Button onClick={startCreate}>
              <Plus size={16} />
              {showForm && !editingId ? 'Đóng biểu mẫu' : 'Thêm tài sản'}
            </Button>
          </div>
        </div>

        <div className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div className="rounded-2xl border border-border/70 bg-bg px-4 py-3">
            <div className="flex items-center justify-between gap-3">
              <p className="text-xs text-fg-muted">Tài sản đang quản lý</p>
              <Building2 size={14} className="text-fg-subtle" />
            </div>
            <p className="mt-3 text-2xl font-semibold tracking-[-0.02em] text-fg">{propertyList.length}</p>
          </div>

          <div className="rounded-2xl border border-border/70 bg-bg px-4 py-3">
            <div className="flex items-center justify-between gap-3">
              <p className="text-xs text-fg-muted">Loại đang hoạt động</p>
              <FolderTree size={14} className="text-fg-subtle" />
            </div>
            <p className="mt-3 text-2xl font-semibold tracking-[-0.02em] text-fg">{activePropertyTypes.length}</p>
          </div>

          <div className="rounded-2xl border border-border/70 bg-bg px-4 py-3">
            <div className="flex items-center justify-between gap-3">
              <p className="text-xs text-fg-muted">Loại tạm ngưng</p>
              <Tag size={14} className="text-fg-subtle" />
            </div>
            <p className="mt-3 text-2xl font-semibold tracking-[-0.02em] text-fg">{inactivePropertyTypes.length}</p>
          </div>
        </div>
      </section>

      {isTypePanelVisible && (
        <section className="mb-6 rounded-[24px] border border-border/80 bg-bg px-5 py-5">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div className="max-w-2xl">
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-fg-subtle">Danh mục cấu hình</p>
              <h3 className="mt-1 text-lg font-semibold tracking-[-0.01em] text-fg">Loại tài sản</h3>
              <p className="mt-1 text-sm leading-6 text-fg-muted">
                Dùng để phân nhóm tài sản khi tạo mới. Mỗi loại có thể được nhiều tài sản dùng chung.
              </p>
            </div>

            <Button size="sm" onClick={startCreateType}>
              <Plus size={16} />
              {showTypeForm && !editingTypeId ? 'Đóng biểu mẫu' : 'Thêm loại tài sản'}
            </Button>
          </div>

          {showTypeForm && (
            <div className="mt-4 rounded-2xl border border-border/80 bg-surface p-4">
              <form onSubmit={(e) => { e.preventDefault(); saveType.mutate(typeForm) }} className="grid grid-cols-1 gap-3 md:grid-cols-4">
                <Input label="Mã loại" value={typeForm.code} onChange={e => setTypeForm({ ...typeForm, code: e.target.value })} required />
                <Input label="Tên loại" value={typeForm.name} onChange={e => setTypeForm({ ...typeForm, name: e.target.value })} required />
                <Input label="Mô tả" value={typeForm.description} onChange={e => setTypeForm({ ...typeForm, description: e.target.value })} />
                <div className="flex items-end gap-2">
                  <Button type="submit" loading={saveType.isPending}>{editingTypeId ? 'Lưu thay đổi' : 'Tạo loại'}</Button>
                  <Button type="button" variant="secondary" onClick={resetTypeForm}>Huỷ</Button>
                </div>
              </form>
            </div>
          )}

          <div className="mt-4 grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
            {propertyTypes.map(type => (
              <div key={type.id} className="rounded-2xl border border-border/80 bg-surface p-4">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="font-semibold text-fg">{type.name}</p>
                      <Badge status={type.active ? 'ACTIVE' : 'INACTIVE'} />
                    </div>
                    <p className="mt-2 inline-flex rounded-md bg-sidebar px-2.5 py-1 text-xs font-medium text-fg-subtle">
                      {type.code}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-[11px] uppercase tracking-[0.12em] text-fg-subtle">Đang dùng</p>
                    <p className="mt-1 text-xl font-semibold text-fg">{propertyCountByTypeId[type.id] ?? 0}</p>
                  </div>
                </div>

                {type.description && <p className="mt-3 text-sm leading-6 text-fg-muted">{type.description}</p>}

                <div className="mt-4 flex flex-wrap gap-2">
                  <Button type="button" variant="secondary" size="sm" onClick={() => startEditType(type)}>Sửa</Button>
                  <Button
                    type="button"
                    variant={type.active ? 'outline' : 'primary'}
                    size="sm"
                    onClick={() => toggleTypeActive.mutate({ id: type.id, active: !type.active })}
                    disabled={toggleTypeActive.isPending}
                  >
                    {type.active ? 'Vô hiệu hóa' : 'Kích hoạt'}
                  </Button>
                  <Button type="button" variant="danger" size="sm" onClick={() => setDeletingType(type)}>
                    Xóa
                  </Button>
                </div>
              </div>
            ))}

            {propertyTypes.length === 0 && (
              <div className="rounded-2xl border border-dashed border-border bg-surface px-4 py-6 text-sm text-fg-subtle">
                Chưa có loại tài sản nào. Hãy tạo ít nhất một loại để bắt đầu thêm tài sản.
              </div>
            )}
          </div>
        </section>
      )}

      {showForm && (
        <Card className="mb-6">
          <CardHeader>{editingId ? 'Cập nhật tài sản' : 'Tạo tài sản mới'}</CardHeader>
          <CardContent>
            <form onSubmit={(e) => { e.preventDefault(); save.mutate(form) }} className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <Input label="Tên tài sản" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required />
              <Input label="Địa chỉ" value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} required />
              <div className="space-y-1">
                <label className="block text-sm font-medium text-fg">Loại hình tài sản</label>
                <select
                  className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg"
                  value={form.propertyTypeId}
                  onChange={e => setForm({ ...form, propertyTypeId: e.target.value })}
                  required
                >
                  <option value="" disabled>Chọn loại hình tài sản</option>
                  {activePropertyTypes.map(type => <option key={type.id} value={type.id}>{type.name}</option>)}
                </select>
                <p className="text-xs text-fg-subtle">Chọn từ danh mục loại tài sản đã cấu hình ở phía trên.</p>
              </div>
              <Input label="Mô tả" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
              <div className="flex gap-2 md:col-span-2">
                <Button type="submit" loading={save.isPending} disabled={!form.propertyTypeId}>
                  {save.isPending ? 'Đang lưu...' : editingId ? 'Lưu thay đổi' : 'Tạo tài sản'}
                </Button>
                <Button type="button" variant="secondary" onClick={resetForm}>Huỷ</Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-accent border-t-transparent" />
        </div>
      ) : propertyList.length === 0 ? (
        <div className="rounded-[24px] border border-dashed border-border bg-surface px-6 py-12 text-center text-fg-subtle">
          Chưa có tài sản nào
        </div>
      ) : (
        <section>
          <div className="mb-4">
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-fg-subtle">Tài sản cụ thể</p>
            <h3 className="mt-1 text-lg font-semibold tracking-[-0.01em] text-fg">Danh sách tài sản</h3>
            <p className="mt-1 text-sm text-fg-muted">Mỗi thẻ là một địa chỉ đang quản lý và được gắn với một loại hình ở trên.</p>
          </div>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            {propertyList.map(p => (
              <Card key={p.id}>
                <CardContent className="p-6">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <h3 className="font-semibold text-fg">{p.name}</h3>
                      <p className="mt-1 text-sm text-fg-muted">{p.address}</p>
                    </div>
                  </div>
                  <div className="mt-4 grid grid-cols-2 gap-3 rounded-xl border border-border bg-sidebar p-3 text-xs">
                    <div>
                      <p className="text-fg-subtle">Loại hình</p>
                      <p className="mt-1 font-medium text-fg">{p.propertyTypeName}</p>
                    </div>
                    <div>
                      <p className="text-fg-subtle">Trạng thái</p>
                      <p className="mt-1"><Badge status="ACTIVE" /></p>
                    </div>
                  </div>
                  {p.description && <p className="mt-3 text-sm text-fg-muted">{p.description}</p>}
                  <p className="mt-4 text-xs text-fg-subtle">Tạo: {formatDate(p.createdAt)}</p>
                  <div className="mt-5 flex gap-2">
                    <Button type="button" variant="secondary" size="sm" onClick={() => startEdit(p)}>Sửa</Button>
                    <Button type="button" variant="danger" size="sm" onClick={() => setDeletingProperty(p)}>Xóa</Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>
      )}

      <Dialog open={!!deletingProperty} onClose={() => setDeletingProperty(null)} title="Xóa tài sản?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">
            Bạn sắp xóa tài sản <span className="font-semibold text-fg">{deletingProperty?.name}</span>. Các phòng và cấu hình liên quan cũng sẽ bị xóa. Hành động này không thể hoàn tác.
          </p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setDeletingProperty(null)}>Huỷ</Button>
            <Button type="button" variant="danger" loading={remove.isPending} onClick={() => deletingProperty && remove.mutate(deletingProperty.id)}>
              Xác nhận xóa
            </Button>
          </div>
        </div>
      </Dialog>

      <Dialog open={!!deletingType} onClose={() => setDeletingType(null)} title="Xóa loại tài sản?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">
            Bạn sắp xóa loại tài sản <span className="font-semibold text-fg">{deletingType?.name}</span>. Hành động này không thể hoàn tác.
          </p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setDeletingType(null)}>Huỷ</Button>
            <Button type="button" variant="danger" loading={removeType.isPending} onClick={() => deletingType && removeType.mutate(deletingType.id)}>
              Xác nhận xóa
            </Button>
          </div>
        </div>
      </Dialog>
    </Layout>
  )
}
