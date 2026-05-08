import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Spinner } from '@/components/ui/feedback'
import api from '@/lib/api'
import type { Room, User } from '@/types'

interface Contract {
  id: string
  room: { id: string; roomNumber: string; property: { name: string } }
  tenant: { id: string; fullName: string; email: string }
  moveInDate: string
  moveOutDate?: string
  status: string
  depositAmount: number
  notes?: string
}

interface CreateForm {
  roomId: string
  tenantId: string
  moveInDate: string
  depositAmount: string
  notes: string
}

const emptyForm = (): CreateForm => ({
  roomId: '', tenantId: '', moveInDate: '', depositAmount: '', notes: '',
})

export default function ContractsPage() {
  const qc = useQueryClient()
  const [terminating, setTerminating] = useState<string | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [form, setForm] = useState<CreateForm>(emptyForm())
  const [formError, setFormError] = useState<string | null>(null)

  const { data: contracts, isLoading, error } = useQuery<Contract[]>({
    queryKey: ['admin-contracts'],
    queryFn: () => api.get('/contracts').then(r => r.data),
  })

  const { data: emptyRooms } = useQuery<Room[]>({
    queryKey: ['rooms-empty'],
    queryFn: () => api.get('/rooms').then(r =>
      (r.data as Room[]).filter(rm => rm.status === 'EMPTY')
    ),
    enabled: showCreate,
  })

  const { data: tenants } = useQuery<User[]>({
    queryKey: ['tenants'],
    queryFn: () => api.get('/users').then(r =>
      (r.data as User[]).filter(u => u.role === 'TENANT' && u.active)
    ),
    enabled: showCreate,
  })

  const terminateMutation = useMutation({
    mutationFn: (id: string) => api.post(`/contracts/${id}/terminate`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-contracts'] })
      setTerminating(null)
    },
  })

  const createMutation = useMutation({
    mutationFn: (data: object) =>
      api.post(`/rooms/${form.roomId}/contracts`, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-contracts'] })
      qc.invalidateQueries({ queryKey: ['rooms-empty'] })
      setShowCreate(false)
      setForm(emptyForm())
      setFormError(null)
    },
    onError: (e: any) => {
      setFormError(e?.response?.data?.message ?? 'Failed to create contract')
    },
  })

  function handleCreate(e: React.FormEvent) {
    e.preventDefault()
    if (!form.roomId || !form.tenantId || !form.moveInDate || !form.depositAmount) {
      setFormError('All required fields must be filled')
      return
    }
    setFormError(null)
    createMutation.mutate({
      tenantId: form.tenantId,
      moveInDate: form.moveInDate,
      depositAmount: Number(form.depositAmount),
      notes: form.notes || null,
    })
  }

  if (isLoading) return <Layout><Spinner /></Layout>
  if (error) return <Layout><div className="p-6 text-red-600">Failed to load contracts</div></Layout>

  return (
    <Layout>
      <div className="p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Hợp đồng</h1>
          <Button variant="primary" onClick={() => { setShowCreate(true); setForm(emptyForm()); setFormError(null) }}>
            + Tạo hợp đồng
          </Button>
        </div>

        {/* Create modal */}
        {showCreate && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <Card className="w-full max-w-lg mx-4 p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Tạo hợp đồng mới</h2>
              <form onSubmit={handleCreate} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Phòng <span className="text-red-500">*</span></label>
                  <select
                    required
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    value={form.roomId}
                    onChange={e => setForm(f => ({ ...f, roomId: e.target.value }))}
                  >
                    <option value="">Chọn phòng trống…</option>
                    {emptyRooms?.map(r => (
                      <option key={r.id} value={r.id}>
                        {r.roomNumber} — {r.property?.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Khách thuê <span className="text-red-500">*</span></label>
                  <select
                    required
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    value={form.tenantId}
                    onChange={e => setForm(f => ({ ...f, tenantId: e.target.value }))}
                  >
                    <option value="">Chọn khách thuê…</option>
                    {tenants?.map(t => (
                      <option key={t.id} value={t.id}>{t.fullName} — {t.email}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Ngày vào <span className="text-red-500">*</span></label>
                  <Input
                    type="date"
                    required
                    value={form.moveInDate}
                    onChange={e => setForm(f => ({ ...f, moveInDate: e.target.value }))}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Tiền đặt cọc (₫) <span className="text-red-500">*</span></label>
                  <Input
                    type="number"
                    required
                    min="0"
                    placeholder="0"
                    value={form.depositAmount}
                    onChange={e => setForm(f => ({ ...f, depositAmount: e.target.value }))}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Ghi chú</label>
                  <textarea
                    rows={2}
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                    placeholder="Tuỳ chọn"
                    value={form.notes}
                    onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
                  />
                </div>

                {formError && <p className="text-sm text-red-600">{formError}</p>}

                <div className="flex gap-3 pt-2">
                  <Button
                    type="button"
                    variant="outline"
                    className="flex-1"
                    onClick={() => { setShowCreate(false); setFormError(null) }}
                  >
                    Huỷ
                  </Button>
                  <Button
                    type="submit"
                    variant="primary"
                    className="flex-1"
                    disabled={createMutation.isPending}
                  >
                    {createMutation.isPending ? 'Đang tạo…' : 'Tạo hợp đồng'}
                  </Button>
                </div>
              </form>
            </Card>
          </div>
        )}

        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  {['Phòng', 'Toà nhà', 'Khách thuê', 'Ngày vào', 'Ngày ra', 'Đặt cọc', 'Trạng thái', 'Thao tác'].map(h => (
                    <th key={h} className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {contracts?.map(c => (
                  <tr key={c.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">{c.room.roomNumber}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{c.room.property.name}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      <div>{c.tenant.fullName}</div>
                      <div className="text-xs text-gray-400">{c.tenant.email}</div>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">{c.moveInDate}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{c.moveOutDate ?? '—'}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{Number(c.depositAmount).toLocaleString('vi-VN')} ₫</td>
                    <td className="px-4 py-3">
                      <Badge status={c.status} />
                    </td>
                    <td className="px-4 py-3">
                      {c.status === 'ACTIVE' && (
                        terminating === c.id ? (
                          <div className="flex gap-2">
                            <Button size="sm" variant="danger"
                              onClick={() => terminateMutation.mutate(c.id)}
                              disabled={terminateMutation.isPending}>
                              Xác nhận
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => setTerminating(null)}>Huỷ</Button>
                          </div>
                        ) : (
                          <Button size="sm" variant="outline" onClick={() => setTerminating(c.id)}>
                            Chấm dứt
                          </Button>
                        )
                      )}
                    </td>
                  </tr>
                ))}
                {contracts?.length === 0 && (
                  <tr><td colSpan={8} className="px-4 py-8 text-center text-gray-400">Chưa có hợp đồng</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </Layout>
  )
}
