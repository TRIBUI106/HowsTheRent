import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, useEffect } from 'react'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { formatCurrency } from '@/lib/utils'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import type { Property, Room } from '@/types'

export default function RoomsPage() {
  const qc = useQueryClient()
  const [selectedProperty, setSelectedProperty] = useState<string>('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ roomNumber: '', floor: '', areaM2: '', maxPeople: '', rentOverride: '' })

  const { data: properties } = useQuery<Property[]>({
    queryKey: ['properties'],
    queryFn: () => api.get('/properties/mine').then(r => r.data),
  })

  useEffect(() => {
    if (properties?.length && !selectedProperty) setSelectedProperty(properties[0].id)
  }, [properties])

  const { data: rooms, isLoading } = useQuery<Room[]>({
    queryKey: ['rooms', selectedProperty],
    queryFn: () => api.get(`/properties/${selectedProperty}/rooms`).then(r => r.data),
    enabled: !!selectedProperty,
  })

  const create = useMutation({
    mutationFn: (d: any) => api.post(`/properties/${selectedProperty}/rooms`, d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['rooms'] }); setShowForm(false); setForm({ roomNumber: '', floor: '', areaM2: '', maxPeople: '', rentOverride: '' }) },
  })

  return (
    <Layout title="Phòng">
      <div className="flex justify-between items-center mb-6">
        <select
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
          value={selectedProperty}
          onChange={e => setSelectedProperty(e.target.value)}
        >
          {properties?.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <Button onClick={() => setShowForm(!showForm)}>{showForm ? 'Đóng' : '+ Thêm phòng'}</Button>
      </div>

      {showForm && (
        <Card className="mb-6">
          <CardHeader>Tạo phòng mới</CardHeader>
          <CardContent>
            <form onSubmit={(e) => { e.preventDefault(); create.mutate({ roomNumber: form.roomNumber, floor: form.floor ? Number(form.floor) : null, areaM2: form.areaM2 ? Number(form.areaM2) : null, maxPeople: Number(form.maxPeople), rentOverride: form.rentOverride ? Number(form.rentOverride) : null }) }} className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Input label="Số phòng" value={form.roomNumber} onChange={e => setForm({ ...form, roomNumber: e.target.value })} required />
              <Input label="Tầng" type="number" value={form.floor} onChange={e => setForm({ ...form, floor: e.target.value })} />
              <Input label="Diện tích (m²)" type="number" value={form.areaM2} onChange={e => setForm({ ...form, areaM2: e.target.value })} />
              <Input label="Số người tối đa" type="number" value={form.maxPeople} onChange={e => setForm({ ...form, maxPeople: e.target.value })} required />
              <Input label="Giá thuê (override)" type="number" value={form.rentOverride} onChange={e => setForm({ ...form, rentOverride: e.target.value })} />
              <div className="flex items-end">
                <Button type="submit" disabled={create.isPending}>{create.isPending ? 'Đang tạo...' : 'Tạo phòng'}</Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
        </div>
      ) : (
        <Card>
          <Table headers={['Số phòng', 'Tầng', 'Diện tích', 'Tối đa', 'Giá', 'Trạng thái']}>
            {rooms?.map(room => (
              <TableRow key={room.id}>
                <TableCell>{room.roomNumber}</TableCell>
                <TableCell>{room.floor ?? '-'}</TableCell>
                <TableCell>{room.areaM2 ? `${room.areaM2}m²` : '-'}</TableCell>
                <TableCell>{room.maxPeople} người</TableCell>
                <TableCell>{formatCurrency(room.rentOverride ?? 0)}</TableCell>
                <TableCell><Badge status={room.status} /></TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}
    </Layout>
  )
}