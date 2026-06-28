import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { TableSkeleton } from '@/components/ui/feedback'
import api from '@/lib/api'
import { userApi } from '@/api'
import type { Room, User } from '@/types'
import { Download } from 'lucide-react'

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

  const [renewing, setRenewing] = useState<string | null>(null)
  const [renewForm, setRenewForm] = useState({ newEndDate: '', newDepositAmount: '' })
  const [renewError, setRenewError] = useState('')

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
    queryFn: () => userApi.listAll().then(users => users.filter(u => u.role === 'TENANT' && u.active)),
    enabled: showCreate,
  })

  const terminateMutation = useMutation({
    mutationFn: (id: string) => api.post(`/contracts/${id}/terminate`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-contracts'] })
      setTerminating(null)
    },
  })

  const renewMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: object }) => api.post(`/contracts/${id}/renew`, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-contracts'] })
      setRenewing(null)
      setRenewForm({ newEndDate: '', newDepositAmount: '' })
      setRenewError('')
    },
    onError: (e: any) => setRenewError(e?.response?.data?.message ?? 'Lỗi'),
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
      setFormError(e?.response?.data?.message ?? 'Không thể tạo hợp đồng')
    },
  })

  function handleCreate(e: React.FormEvent) {
    e.preventDefault()
    if (!form.roomId || !form.tenantId || !form.moveInDate || !form.depositAmount) {
      setFormError('Vui lòng điền đầy đủ các trường bắt buộc')
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

  if (isLoading) return <Layout><TableSkeleton rows={6} columns={8} /></Layout>
  if (error) return <Layout><div className="text-error">Không thể tải danh sách hợp đồng</div></Layout>

  return (
    <Layout>
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-fg">Hợp đồng</h1>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={() => {
              api.get('/export/contracts', { responseType: 'blob' })
                .then(r => r.data)
                .then(blob => {
                  const url = URL.createObjectURL(blob)
                  const a = document.createElement('a')
                  a.href = url; a.download = 'hopdong.xlsx'; a.click()
                  URL.revokeObjectURL(url)
                })
            }}>
              <Download size={14} className="mr-1" /> Excel
            </Button>
            <Button variant="primary" onClick={() => { setShowCreate(true); setForm(emptyForm()); setFormError(null) }}>
              + Tạo hợp đồng
            </Button>
          </div>
        </div>

        {showCreate && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <Card className="w-full max-w-lg mx-4 p-6 animate-scale-in">
              <h2 className="text-lg font-semibold text-fg mb-4">Tạo hợp đồng mới</h2>
              <form onSubmit={handleCreate} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-fg mb-1">Phòng <span className="text-error">*</span></label>
                  <select
                    required
                    className="w-full border border-border/80 rounded-xl px-3 py-2 text-sm bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    value={form.roomId}
                    onChange={e => setForm(f => ({ ...f, roomId: e.target.value }))}
                  >
                    <option value="">Chọn phòng trống...</option>
                    {emptyRooms?.map(r => (
                      <option key={r.id} value={r.id}>
                        {r.roomNumber} — {r.property?.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-fg mb-1">Khách thuê <span className="text-error">*</span></label>
                  <select
                    required
                    className="w-full border border-border/80 rounded-xl px-3 py-2 text-sm bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    value={form.tenantId}
                    onChange={e => setForm(f => ({ ...f, tenantId: e.target.value }))}
                  >
                    <option value="">Chọn khách thuê...</option>
                    {tenants?.map(t => (
                      <option key={t.id} value={t.id}>{t.fullName} — {t.email}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-fg mb-1">Ngày vào <span className="text-error">*</span></label>
                  <Input
                    type="date"
                    required
                    value={form.moveInDate}
                    onChange={e => setForm(f => ({ ...f, moveInDate: e.target.value }))}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-fg mb-1">Tiền đặt cọc (₫) <span className="text-error">*</span></label>
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
                  <label className="block text-sm font-medium text-fg mb-1">Ghi chú</label>
                  <textarea
                    rows={2}
                    className="w-full border border-border/80 rounded-xl px-3 py-2 text-sm bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent resize-none"
                    placeholder="Tuỳ chọn"
                    value={form.notes}
                    onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
                  />
                </div>

                {formError && <p className="text-sm text-error">{formError}</p>}

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
                    {createMutation.isPending ? 'Đang tạo...' : 'Tạo hợp đồng'}
                  </Button>
                </div>
              </form>
            </Card>
          </div>
        )}

        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-border/60">
              <thead className="bg-sidebar/50">
                <tr>
                  {['Phòng', 'Toà nhà', 'Khách thuê', 'Ngày vào', 'Ngày ra', 'Đặt cọc', 'Trạng thái', 'Thao tác'].map(h => (
                    <th key={h} className="px-4 py-3 text-left text-xs font-medium text-fg-muted uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="bg-surface divide-y divide-border/60">
                {contracts?.map(c => (
                  <tr key={c.id} className="hover:bg-sidebar/30 transition-colors">
                    <td className="px-4 py-3 text-sm font-medium text-fg">{c.room.roomNumber}</td>
                    <td className="px-4 py-3 text-sm text-fg-muted">{c.room.property.name}</td>
                    <td className="px-4 py-3 text-sm text-fg-muted">
                      <div>{c.tenant.fullName}</div>
                      <div className="text-xs text-fg-subtle">{c.tenant.email}</div>
                    </td>
                    <td className="px-4 py-3 text-sm text-fg-muted">{c.moveInDate}</td>
                    <td className="px-4 py-3 text-sm text-fg-muted">{c.moveOutDate ?? '—'}</td>
                    <td className="px-4 py-3 text-sm text-fg-muted">{Number(c.depositAmount).toLocaleString('vi-VN')} ₫</td>
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
                        ) : renewing === c.id ? (
                          <div className="flex flex-col gap-2">
                            <div className="flex gap-1">
                              <input type="date" value={renewForm.newEndDate}
                                onChange={e => setRenewForm(f => ({ ...f, newEndDate: e.target.value }))}
                                className="border border-border/80 rounded-lg px-2 py-1 text-xs w-32 bg-surface text-fg" />
                              <input type="number" placeholder="Đặt cọc mới"
                                value={renewForm.newDepositAmount}
                                onChange={e => setRenewForm(f => ({ ...f, newDepositAmount: e.target.value }))}
                                className="border border-border/80 rounded-lg px-2 py-1 text-xs w-24 bg-surface text-fg" />
                            </div>
                            {renewError && <p className="text-xs text-error">{renewError}</p>}
                            <div className="flex gap-2">
                              <Button size="sm" variant="primary" onClick={() => {
                                if (!renewForm.newEndDate) { setRenewError('Cần chọn ngày kết thúc'); return }
                                renewMutation.mutate({ id: c.id, data: { newStartDate: new Date().toISOString().slice(0,10), newEndDate: renewForm.newEndDate, newDepositAmount: Number(renewForm.newDepositAmount) || null } })
                              }} disabled={renewMutation.isPending}>
                                Xác nhận
                              </Button>
                              <Button size="sm" variant="outline" onClick={() => { setRenewing(null); setRenewError('') }}>Huỷ</Button>
                            </div>
                          </div>
                        ) : (
                          <div className="flex gap-2">
                            <Button size="sm" variant="outline" onClick={() => setTerminating(c.id)}>
                              Chấm dứt
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => { setRenewing(c.id); setRenewError('') }}>
                              Gia hạn
                            </Button>
                          </div>
                        )
                      )}
                    </td>
                  </tr>
                ))}
                {contracts?.length === 0 && (
                  <tr><td colSpan={8} className="px-4 py-8 text-center text-fg-subtle">Chưa có hợp đồng</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </Layout>
  )
}
