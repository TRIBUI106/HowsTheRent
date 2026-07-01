import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { TableSkeleton } from '@/components/ui/feedback'
import api from '@/lib/api'
import { getRoomPropertyName, normalizeContract } from '@/lib/apiMappers'
import { userApi } from '@/api'
import type { Contract, Room, User } from '@/types'
import { Download } from 'lucide-react'

interface ContractApiRow {
  id: string
  roomId: string
  roomNumber: string
  propertyId: string
  propertyName: string
  tenantId: string
  tenantName: string
  tenantEmail: string
  moveInDate: string
  moveOutDate?: string
  status: Contract['status']
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
  roomId: '',
  tenantId: '',
  moveInDate: '',
  depositAmount: '',
  notes: '',
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

  const { data: contractsData, isLoading, error } = useQuery<ContractApiRow[]>({
    queryKey: ['admin-contracts'],
    queryFn: () => api.get('/contracts').then(r => r.data),
  })

  const { data: emptyRooms } = useQuery<Room[]>({
    queryKey: ['rooms-empty'],
    queryFn: () => api.get<Room[]>('/rooms').then(r => r.data.filter(room => room.status === 'EMPTY')),
    enabled: showCreate,
  })

  const { data: tenants } = useQuery<User[]>({
    queryKey: ['tenants'],
    queryFn: () => userApi.listAll().then(users => users.filter(user => user.role?.toUpperCase() === 'TENANT' && user.active)),
    enabled: showCreate,
  })

  const contracts: Contract[] = (contractsData ?? []).map(normalizeContract)

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
    mutationFn: (data: object) => api.post(`/rooms/${form.roomId}/contracts`, data),
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
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                api.get('/export/contracts', { responseType: 'blob' })
                  .then(r => r.data)
                  .then(blob => {
                    const url = URL.createObjectURL(blob)
                    const anchor = document.createElement('a')
                    anchor.href = url
                    anchor.download = 'hopdong.xlsx'
                    anchor.click()
                    URL.revokeObjectURL(url)
                  })
              }}
            >
              <Download size={14} className="mr-1" /> Excel
            </Button>
            <Button variant="primary" onClick={() => { setShowCreate(true); setForm(emptyForm()); setFormError(null) }}>
              + Tạo hợp đồng
            </Button>
          </div>
        </div>

        {showCreate && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <Card className="mx-4 w-full max-w-lg p-6 animate-scale-in">
              <h2 className="mb-4 text-lg font-semibold text-fg">Tạo hợp đồng mới</h2>
              <form onSubmit={handleCreate} className="space-y-4">
                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Phòng <span className="text-error">*</span></label>
                  <select
                    required
                    className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    value={form.roomId}
                    onChange={e => setForm(current => ({ ...current, roomId: e.target.value }))}
                  >
                    <option value="">Chọn phòng trống...</option>
                    {emptyRooms?.map(room => (
                      <option key={room.id} value={room.id}>
                        {room.roomNumber} - {getRoomPropertyName(room)}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Khách thuê <span className="text-error">*</span></label>
                  <select
                    required
                    className="w-full rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    value={form.tenantId}
                    onChange={e => setForm(current => ({ ...current, tenantId: e.target.value }))}
                  >
                    <option value="">Chọn khách thuê...</option>
                    {tenants?.map(tenant => (
                      <option key={tenant.id} value={tenant.id}>
                        {tenant.fullName} - {tenant.email}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Ngày vào <span className="text-error">*</span></label>
                  <Input
                    type="date"
                    required
                    value={form.moveInDate}
                    onChange={e => setForm(current => ({ ...current, moveInDate: e.target.value }))}
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Tiền đặt cọc (VND) <span className="text-error">*</span></label>
                  <Input
                    type="number"
                    required
                    min="0"
                    placeholder="0"
                    value={form.depositAmount}
                    onChange={e => setForm(current => ({ ...current, depositAmount: e.target.value }))}
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm font-medium text-fg">Ghi chú</label>
                  <textarea
                    rows={2}
                    className="w-full resize-none rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                    placeholder="Tùy chọn"
                    value={form.notes}
                    onChange={e => setForm(current => ({ ...current, notes: e.target.value }))}
                  />
                </div>

                {formError && <p className="text-sm text-error">{formError}</p>}

                <div className="flex gap-3 pt-2">
                  <Button type="button" variant="outline" className="flex-1" onClick={() => { setShowCreate(false); setFormError(null) }}>
                    Hủy
                  </Button>
                  <Button type="submit" variant="primary" className="flex-1" disabled={createMutation.isPending}>
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
                  {['Phòng', 'Tòa nhà', 'Khách thuê', 'Ngày vào', 'Ngày ra', 'Đặt cọc', 'Trạng thái', 'Thao tác'].map(header => (
                    <th key={header} className="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-fg-muted">{header}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-border/60 bg-surface">
                {contracts.map(contract => (
                  <tr key={contract.id} className="transition-colors hover:bg-sidebar/30">
                    <td className="px-4 py-3 text-sm font-medium text-fg">{contract.room.roomNumber}</td>
                    <td className="px-4 py-3 text-sm text-fg-muted">{contract.room.propertyName}</td>
                    <td className="px-4 py-3 text-sm text-fg-muted">
                      <div>{contract.tenant.fullName}</div>
                      <div className="text-xs text-fg-subtle">{contract.tenant.email}</div>
                    </td>
                    <td className="px-4 py-3 text-sm text-fg-muted">{contract.moveInDate}</td>
                    <td className="px-4 py-3 text-sm text-fg-muted">{contract.moveOutDate ?? '-'}</td>
                    <td className="px-4 py-3 text-sm text-fg-muted">{Number(contract.depositAmount).toLocaleString('vi-VN')} VND</td>
                    <td className="px-4 py-3">
                      <Badge status={contract.status} />
                    </td>
                    <td className="px-4 py-3">
                      {contract.status === 'ACTIVE' && (
                        terminating === contract.id ? (
                          <div className="flex gap-2">
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() => terminateMutation.mutate(contract.id)}
                              disabled={terminateMutation.isPending}
                            >
                              Xác nhận
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => setTerminating(null)}>Hủy</Button>
                          </div>
                        ) : renewing === contract.id ? (
                          <div className="flex flex-col gap-2">
                            <div className="flex gap-1">
                              <input
                                type="date"
                                value={renewForm.newEndDate}
                                onChange={e => setRenewForm(current => ({ ...current, newEndDate: e.target.value }))}
                                className="w-32 rounded-lg border border-border/80 bg-surface px-2 py-1 text-xs text-fg"
                              />
                              <input
                                type="number"
                                placeholder="Đặt cọc mới"
                                value={renewForm.newDepositAmount}
                                onChange={e => setRenewForm(current => ({ ...current, newDepositAmount: e.target.value }))}
                                className="w-24 rounded-lg border border-border/80 bg-surface px-2 py-1 text-xs text-fg"
                              />
                            </div>
                            {renewError && <p className="text-xs text-error">{renewError}</p>}
                            <div className="flex gap-2">
                              <Button
                                size="sm"
                                variant="primary"
                                onClick={() => {
                                  if (!renewForm.newEndDate) {
                                    setRenewError('Cần chọn ngày kết thúc')
                                    return
                                  }

                                  renewMutation.mutate({
                                    id: contract.id,
                                    data: {
                                      newStartDate: new Date().toISOString().slice(0, 10),
                                      newEndDate: renewForm.newEndDate,
                                      newDepositAmount: Number(renewForm.newDepositAmount) || null,
                                    },
                                  })
                                }}
                                disabled={renewMutation.isPending}
                              >
                                Xác nhận
                              </Button>
                              <Button size="sm" variant="outline" onClick={() => { setRenewing(null); setRenewError('') }}>Hủy</Button>
                            </div>
                          </div>
                        ) : (
                          <div className="flex gap-2">
                            <Button size="sm" variant="outline" onClick={() => setTerminating(contract.id)}>
                              Chấm dứt
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => { setRenewing(contract.id); setRenewError('') }}>
                              Gia hạn
                            </Button>
                          </div>
                        )
                      )}
                    </td>
                  </tr>
                ))}
                {contracts.length === 0 && (
                  <tr>
                    <td colSpan={8} className="px-4 py-8 text-center text-fg-subtle">Chưa có hợp đồng</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </Layout>
  )
}
