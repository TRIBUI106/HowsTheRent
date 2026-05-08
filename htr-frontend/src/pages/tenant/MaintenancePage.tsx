import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatDate } from '@/lib/utils'
import type { MaintenanceRequest, Contract } from '@/types'
import { Plus, X } from 'lucide-react'

export default function TenantMaintenancePage() {
  const queryClient = useQueryClient()
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ title: '', description: '', roomId: '' })

  const { data: requests, isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tenant-maintenance'],
    queryFn: () => api.get('/maintenance/mine').then(r => r.data),
  })

  const { data: contracts } = useQuery<Contract[]>({
    queryKey: ['my-contracts'],
    queryFn: () => api.get('/contracts/mine').then(r => r.data),
    enabled: showForm,
  })

  const createMutation = useMutation({
    mutationFn: (data: { title: string; description: string; roomId: string }) =>
      api.post('/maintenance', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tenant-maintenance'] })
      setShowForm(false)
      setForm({ title: '', description: '', roomId: '' })
    },
  })

  const activeRooms = contracts?.filter(c => c.status === 'ACTIVE').map(c => c.room) ?? []

  return (
    <Layout title="Bảo trì">
      <div className="space-y-4">
        <div className="flex justify-end">
          <button
            onClick={() => setShowForm(v => !v)}
            className="flex items-center gap-2 text-sm bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors"
          >
            {showForm ? <X size={15} /> : <Plus size={15} />}
            {showForm ? 'Đóng' : 'Tạo yêu cầu'}
          </button>
        </div>

        {showForm && (
          <Card>
            <CardContent className="p-5 space-y-4">
              <p className="font-medium text-gray-900">Yêu cầu bảo trì mới</p>
              <div className="space-y-3">
                <div>
                  <label className="text-sm font-medium text-gray-700 block mb-1">Phòng</label>
                  <select
                    className="w-full border rounded-lg px-3 py-2 text-sm"
                    value={form.roomId}
                    onChange={e => setForm(f => ({ ...f, roomId: e.target.value }))}
                  >
                    <option value="">Chọn phòng</option>
                    {activeRooms.map(r => (
                      <option key={r.id} value={r.id}>{r.roomNumber}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 block mb-1">Tiêu đề</label>
                  <input
                    type="text"
                    className="w-full border rounded-lg px-3 py-2 text-sm"
                    placeholder="Mô tả ngắn gọn sự cố"
                    value={form.title}
                    onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 block mb-1">Chi tiết</label>
                  <textarea
                    rows={3}
                    className="w-full border rounded-lg px-3 py-2 text-sm resize-none"
                    placeholder="Mô tả chi tiết vấn đề..."
                    value={form.description}
                    onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  />
                </div>
              </div>
              <div className="flex justify-end gap-2">
                <button
                  onClick={() => setShowForm(false)}
                  className="text-sm px-4 py-2 border rounded-lg hover:bg-gray-50"
                >
                  Hủy
                </button>
                <button
                  onClick={() => createMutation.mutate(form)}
                  disabled={!form.title || !form.roomId || createMutation.isPending}
                  className="text-sm bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition-colors"
                >
                  {createMutation.isPending ? 'Đang gửi...' : 'Gửi yêu cầu'}
                </button>
              </div>
            </CardContent>
          </Card>
        )}

        {isLoading ? (
          <div className="flex h-32 items-center justify-center">
            <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
          </div>
        ) : (
          <>
            {requests?.map(req => (
              <Card key={req.id}>
                <div className="p-4">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="font-medium text-gray-900">{req.title}</p>
                      <p className="text-sm text-gray-500 mt-1">{req.room?.roomNumber}</p>
                      {req.description && <p className="text-sm text-gray-600 mt-2">{req.description}</p>}
                    </div>
                    <Badge status={req.status} />
                  </div>
                  <p className="text-xs text-gray-400 mt-3">Ngày tạo: {formatDate(req.createdAt)}</p>
                </div>
              </Card>
            ))}
            {requests?.length === 0 && (
              <p className="text-center text-gray-400 py-8">Chưa có yêu cầu bảo trì</p>
            )}
          </>
        )}
      </div>
    </Layout>
  )
}