import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { propertyApi, roomApi, userApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Dialog } from '@/components/ui/dialog'
import { formatCurrency, formatCurrencyInput, parseCurrencyInput } from '@/lib/utils'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import type { Property, Room } from '@/types'

const emptyForm = { roomNumber: '', floor: '', areaM2: '', maxPeople: '', rentOverride: '', status: 'EMPTY' }

export default function RoomsPage() {
  const qc = useQueryClient()
  const navigate = useNavigate()
  const user = useAuthStore(state => state.user)
  const [selectedProperty, setSelectedProperty] = useState<string>('')
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

  useEffect(() => {
    if (properties?.length && !selectedProperty) setSelectedProperty(properties[0].id)
  }, [properties, selectedProperty])

  const { data: rooms, isLoading } = useQuery<Room[]>({
    queryKey: ['rooms', selectedProperty],
    queryFn: () => roomApi.listByProperty(selectedProperty),
    enabled: !!user && !!sessionUser && sessionUser.role === 'ADMIN' && !!selectedProperty,
  })

  const resetForm = () => {
    setShowForm(false)
    setEditingId(null)
    setForm(emptyForm)
  }

  const save = useMutation({
    mutationFn: async () => {
      const payload = {
        roomNumber: form.roomNumber,
        floor: form.floor ? Number(form.floor) : null,
        areaM2: form.areaM2 ? Number(form.areaM2) : null,
        maxPeople: Number(form.maxPeople),
        rentOverride: form.rentOverride ? parseCurrencyInput(form.rentOverride) : null,
      }
      const room = editingId
        ? await roomApi.update(selectedProperty, editingId, payload)
        : await roomApi.create(selectedProperty, payload)

      if (editingId && form.status !== room.status) {
        await roomApi.updateStatus(selectedProperty, editingId, form.status)
      }

      return room
    },
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['rooms', selectedProperty] }); resetForm() },
  })

  const remove = useMutation({
    mutationFn: (id: string) => roomApi.remove(selectedProperty, id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['rooms', selectedProperty] })
      setDeletingRoom(null)
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
    })
    setShowForm(true)
  }

  return (
    <Layout title="Phòng">
      <div className="flex justify-between items-center mb-6">
        <select
          className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg"
          value={selectedProperty}
          onChange={e => { setSelectedProperty(e.target.value); resetForm() }}
        >
          {properties?.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <Button onClick={startCreate} disabled={!selectedProperty}>{showForm && !editingId ? 'Đóng' : '+ Thêm phòng'}</Button>
      </div>

      {showForm && (
        <Card className="mb-6">
          <CardHeader>{editingId ? 'Cập nhật phòng' : 'Tạo phòng mới'}</CardHeader>
          <CardContent>
            <form onSubmit={(e) => { e.preventDefault(); save.mutate() }} className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Input label="Số phòng" value={form.roomNumber} onChange={e => setForm({ ...form, roomNumber: e.target.value })} required />
              <Input label="Tầng" type="number" value={form.floor} onChange={e => setForm({ ...form, floor: e.target.value })} />
              <Input label="Diện tích (m²)" type="number" value={form.areaM2} onChange={e => setForm({ ...form, areaM2: e.target.value })} />
              <Input label="Số người tối đa" type="number" value={form.maxPeople} onChange={e => setForm({ ...form, maxPeople: e.target.value })} required />
              <Input label="Giá thuê (override)" type="text" inputMode="numeric" value={form.rentOverride} onChange={e => setForm({ ...form, rentOverride: formatCurrencyInput(e.target.value) })} />
              {editingId && (
                <div className="space-y-1">
                  <label className="block text-sm font-medium text-fg">Trạng thái</label>
                  <select className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg" value={form.status} onChange={e => setForm({ ...form, status: e.target.value })}>
                    <option value="EMPTY">Trống</option>
                    <option value="RENTED">Đã thuê</option>
                    <option value="MAINTENANCE">Bảo trì</option>
                  </select>
                </div>
              )}
              <div className="flex items-end gap-2 md:col-span-3">
                <Button type="submit" loading={save.isPending}>{save.isPending ? 'Đang lưu...' : editingId ? 'Lưu thay đổi' : 'Tạo phòng'}</Button>
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
      ) : (
        <Card>
          <Table headers={['Số phòng', 'Tầng', 'Diện tích', 'Tối đa', 'Giá', 'Trạng thái', 'Thao tác']} >
            {rooms?.map(room => (
              <TableRow key={room.id}>
                <TableCell>{room.roomNumber}</TableCell>
                <TableCell>{room.floor ?? '-'}</TableCell>
                <TableCell>{room.areaM2 ? `${room.areaM2}m²` : '-'}</TableCell>
                <TableCell>{room.maxPeople} người</TableCell>
                <TableCell>{formatCurrency(room.rentOverride ?? 0)}</TableCell>
                <TableCell><Badge status={room.status} /></TableCell>
                <TableCell>
                  <div className="flex gap-2">
                    <Button type="button" variant="secondary" size="sm" onClick={() => navigate(`/admin/rooms/${selectedProperty}/${room.id}`)}>Xem</Button>
                    <Button type="button" variant="secondary" size="sm" onClick={() => startEdit(room)}>Sửa</Button>
                    <Button type="button" variant="danger" size="sm" onClick={() => setDeletingRoom(room)}>Xoá</Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}

      <Dialog open={!!deletingRoom} onClose={() => setDeletingRoom(null)} title="Xoá phòng?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">
            Bạn sắp xoá phòng <span className="font-semibold text-fg">{deletingRoom?.roomNumber}</span>. Dữ liệu liên quan đến phòng này có thể bị ảnh hưởng. Hành động này không thể hoàn tác.
          </p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setDeletingRoom(null)}>Huỷ</Button>
            <Button type="button" variant="danger" loading={remove.isPending} onClick={() => deletingRoom && remove.mutate(deletingRoom.id)}>
              Xác nhận xoá
            </Button>
          </div>
        </div>
      </Dialog>
    </Layout>
  )
}
