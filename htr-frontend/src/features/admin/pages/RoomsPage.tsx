import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { propertyApi, roomApi, userApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Dialog } from '@/components/ui/dialog'
import { directionLabel, formatCurrency, formatCurrencyInput, parseCurrencyInput } from '@/lib/utils'
import { Table, TableCell, TableRow } from '@/components/ui/table'
import { getErrorMessage } from '@/lib/apiError'
import { showToast } from '@/lib/toast'
import { ImageOff } from 'lucide-react'
import type { Property, Room, RoomDirection } from '@/types'

const directionOptions: { value: RoomDirection; label: string }[] = [
  'EAST', 'WEST', 'SOUTH', 'NORTH', 'NORTHEAST', 'NORTHWEST', 'SOUTHEAST', 'SOUTHWEST',
].map(value => ({ value: value as RoomDirection, label: directionLabel(value) }))

const emptyForm = { roomNumber: '', floor: '', areaM2: '', maxPeople: '', rentOverride: '', status: 'EMPTY', direction: '', description: '' }

export default function RoomsPage() {
  const qc = useQueryClient()
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const user = useAuthStore((state) => state.user)
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [deletingRoom, setDeletingRoom] = useState<Room | null>(null)
  const [form, setForm] = useState(emptyForm)

  const { data: sessionUser } = useQuery({
    queryKey: ['auth-session'],
    queryFn: userApi.me,
    enabled: !!user,
    retry: false,
    staleTime: 0,
    gcTime: 0,
    refetchOnMount: 'always',
    refetchOnWindowFocus: true,
  })

  const { data: properties } = useQuery<Property[]>({
    queryKey: ['properties'],
    queryFn: propertyApi.list,
    enabled: !!user && !!sessionUser && sessionUser.role === 'ADMIN',
  })

  const queryProperty = searchParams.get('propertyId')
  const queryPropertyExists = !!queryProperty && !!properties?.some((property) => property.id === queryProperty)
  const effectiveSelectedProperty = (queryPropertyExists ? queryProperty : properties?.[0]?.id) || ''

  const selectProperty = (propertyId: string) => {
    setSearchParams(propertyId ? { propertyId } : {})
    resetForm()
  }

  const { data: rooms, isLoading } = useQuery<Room[]>({
    queryKey: ['rooms', effectiveSelectedProperty],
    queryFn: () => roomApi.listByProperty(effectiveSelectedProperty),
    enabled: !!user && !!sessionUser && sessionUser.role === 'ADMIN' && !!effectiveSelectedProperty,
  })

  const resetForm = () => {
    setShowForm(false)
    setEditingId(null)
    setForm(emptyForm)
  }

  const save = useGuardedMutation({
    mutationFn: async () => {
        const payload = {
        roomNumber: form.roomNumber,
        floor: form.floor ? Number(form.floor) : null,
        areaM2: form.areaM2 ? Number(form.areaM2) : null,
        maxPeople: Number(form.maxPeople),
        rentOverride: form.rentOverride ? parseCurrencyInput(form.rentOverride) : null,
        direction: form.direction ? (form.direction as RoomDirection) : null,
        description: form.description.trim() || null,
      }

      const room = editingId
        ? await roomApi.update(effectiveSelectedProperty, editingId, payload)
        : await roomApi.create(effectiveSelectedProperty, payload)

      if (editingId && form.status !== room.status) {
        await roomApi.updateStatus(effectiveSelectedProperty, editingId, form.status)
      }

      return room
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['rooms', effectiveSelectedProperty] })
      qc.invalidateQueries({ queryKey: ['maintenance'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
      resetForm()
    },
  })

  const remove = useGuardedMutation({
    mutationFn: (id: string) => roomApi.remove(effectiveSelectedProperty, id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['rooms', effectiveSelectedProperty] })
      setDeletingRoom(null)
    },
    onError: (err: unknown) => {
      showToast({ message: getErrorMessage(err, 'Xóa phòng thất bại'), type: 'error' })
    },
  })

  function startCreate() {
    if (showForm && !editingId) return resetForm()
    setEditingId(null)
    setForm(emptyForm)
    setShowForm(true)
  }

  function startEdit(room: Room) {
    setEditingId(room.id)
    setForm({
      roomNumber: room.roomNumber,
      floor: room.floor?.toString() || '',
      areaM2: room.areaM2?.toString() || '',
      maxPeople: room.maxPeople.toString(),
      rentOverride: formatCurrencyInput(room.rentOverride),
      status: room.status,
      direction: room.direction ?? '',
      description: room.description ?? '',
    })
    setShowForm(true)
  }

  return (
    <Layout title="Phòng">
      <div className="mb-6 flex items-center justify-between">
        <select
          className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg"
          value={effectiveSelectedProperty}
          onChange={(event) => selectProperty(event.target.value)}
        >
          {properties?.map((property) => (
            <option key={property.id} value={property.id}>{property.name}</option>
          ))}
        </select>
        <Button onClick={startCreate} disabled={!effectiveSelectedProperty}>
          {showForm && !editingId ? 'Đóng' : '+ Thêm phòng'}
        </Button>
      </div>

      {showForm && (
        <Card className="mb-6">
          <CardHeader>{editingId ? 'Cập nhật phòng' : 'Tạo phòng mới'}</CardHeader>
          <CardContent>
            <form onSubmit={(event) => { event.preventDefault(); save.mutate() }} className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <Input label="Số phòng" value={form.roomNumber} onChange={(event) => setForm({ ...form, roomNumber: event.target.value })} required />
              <Input label="Tầng" type="number" value={form.floor} onChange={(event) => setForm({ ...form, floor: event.target.value })} />
              <Input label="Diện tích (m²)" type="number" value={form.areaM2} onChange={(event) => setForm({ ...form, areaM2: event.target.value })} />
              <Input label="Số người tối đa" type="number" value={form.maxPeople} onChange={(event) => setForm({ ...form, maxPeople: event.target.value })} required />
              <Input label="Giá thuê (override)" type="text" inputMode="numeric" value={form.rentOverride} onChange={(event) => setForm({ ...form, rentOverride: formatCurrencyInput(event.target.value) })} />
              <div className="space-y-1">
                <label className="block text-sm font-medium text-fg">Hướng phòng</label>
                <select
                  className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg"
                  value={form.direction}
                  onChange={(event) => setForm({ ...form, direction: event.target.value })}
                >
                  <option value="">Không chọn</option>
                  {directionOptions.map(({ value, label }) => (
                    <option key={value} value={value}>{label}</option>
                  ))}
                </select>
              </div>
              {editingId && (
                <div className="space-y-1">
                  <label className="block text-sm font-medium text-fg">Trạng thái</label>
                  <select
                    className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg"
                    value={form.status}
                    onChange={(event) => setForm({ ...form, status: event.target.value })}
                  >
                    <option value="EMPTY">Trống</option>
                    <option value="RENTED">Đã thuê</option>
                    <option value="MAINTENANCE">Bảo trì</option>
                  </select>
                </div>
              )}

              <div className="space-y-1 md:col-span-3">
                <label className="block text-sm font-medium text-fg">Mô tả phòng</label>
                <textarea
                  rows={2}
                  className="w-full resize-none rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg placeholder:text-fg-subtle focus:outline-none focus:ring-2 focus:ring-accent/40"
                  placeholder="Ví dụ: Phòng sạch, mới, nội thất đầy đủ, tone trắng xám, hướng tây bắc..."
                  value={form.description}
                  onChange={(event) => setForm({ ...form, description: event.target.value })}
                />
              </div>

              <div className="flex items-end gap-2 md:col-span-3">
                <Button type="submit" loading={save.isPending}>
                  {save.isPending ? 'Đang lưu...' : editingId ? 'Lưu thay đổi' : 'Tạo phòng'}
                </Button>
                <Button type="button" variant="secondary" onClick={resetForm}>Hủy</Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-accent border-t-transparent" />
        </div>
      ) : (
        <Card>
          <Table headers={['Ảnh', 'Số phòng', 'Tầng', 'Diện tích', 'Tối đa', 'Giá', 'Hướng', 'Mô tả', 'Trạng thái', 'Thao tác']}>
            {rooms?.map((room) => (
              <TableRow key={room.id}>
                <TableCell>
                  {room.images?.[0] ? (
                    <img src={room.images[0]} alt="" className="h-9 w-9 rounded-lg object-cover border border-border" />
                  ) : (
                    <span className="flex h-9 w-9 items-center justify-center rounded-lg border border-border bg-sidebar/50 text-fg-subtle">
                      <ImageOff size={14} />
                    </span>
                  )}
                </TableCell>
                <TableCell>{room.roomNumber}</TableCell>
                <TableCell>{room.floor ?? '-'}</TableCell>
                <TableCell>{room.areaM2 ? `${room.areaM2}m²` : '-'}</TableCell>
                <TableCell>{room.maxPeople} người</TableCell>
                <TableCell>{formatCurrency(room.rentOverride ?? 0)}</TableCell>
                <TableCell>{directionLabel(room.direction)}</TableCell>
                <TableCell>
                  {room.description ? (
                    <span className="block max-w-[160px] truncate text-fg-muted" title={room.description}>
                      {room.description}
                    </span>
                  ) : (
                    <span className="text-fg-subtle">—</span>
                  )}
                </TableCell>
                <TableCell><Badge status={room.status} /></TableCell>
                <TableCell>
                  <div className="flex gap-2">
                    <Button type="button" variant="secondary" size="sm" onClick={() => navigate(`/admin/rooms/${effectiveSelectedProperty}/${room.id}`)}>Xem</Button>
                    <Button type="button" variant="secondary" size="sm" onClick={() => startEdit(room)}>Sửa</Button>
                    <Button type="button" variant="danger" size="sm" onClick={() => setDeletingRoom(room)}>Xóa</Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}

      <Dialog open={!!deletingRoom} onClose={() => setDeletingRoom(null)} title="Xóa phòng?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">
            Bạn sắp xóa phòng <span className="font-semibold text-fg">{deletingRoom?.roomNumber}</span>.
            Dữ liệu liên quan đến phòng này có thể bị ảnh hưởng. Hành động này không thể hoàn tác.
          </p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setDeletingRoom(null)}>Hủy</Button>
            <Button type="button" variant="danger" loading={remove.isPending} onClick={() => deletingRoom && remove.mutate(deletingRoom.id)}>
              Xác nhận xóa
            </Button>
          </div>
        </div>
      </Dialog>
    </Layout>
  )
}
