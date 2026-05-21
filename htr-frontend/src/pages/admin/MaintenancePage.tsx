import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { formatDate } from '@/lib/utils'
import type { MaintenanceRequest, User } from '@/types'

export default function AdminMaintenancePage() {
  const queryClient = useQueryClient()
  const [assigningId, setAssigningId] = useState<string | null>(null)
  const [selectedTech, setSelectedTech] = useState<Record<string, string>>({})

  const { data: requests, isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['maintenance'],
    queryFn: () => api.get('/maintenance').then(r => r.data),
  })

  const { data: users } = useQuery<User[]>({
    queryKey: ['users'],
    queryFn: () => api.get('/users').then(r => r.data),
  })

  const technicians = users?.filter(u => u.role === 'TECHNICIAN') ?? []

  const assignMutation = useMutation({
    mutationFn: ({ id, techId }: { id: string; techId: string }) =>
      api.post(`/maintenance/${id}/assign?technicianId=${techId}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      setAssigningId(null)
    },
  })

  return (
    <Layout title="Bảo trì">
      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
        </div>
      ) : (
        <Card>
          <Table headers={['Tiêu đề', 'Phòng', 'Người thuê', 'Kỹ thuật viên', 'Trạng thái', 'Ngày tạo', '']}>
            {requests?.map(req => (
              <TableRow key={req.id}>
                <TableCell className="font-medium">{req.title}</TableCell>
                <TableCell>{req.room?.roomNumber}</TableCell>
                <TableCell>{req.tenant?.fullName}</TableCell>
                <TableCell>{req.assignedTo?.fullName ?? <span className="text-gray-400">—</span>}</TableCell>
                <TableCell><Badge status={req.status} /></TableCell>
                <TableCell>{formatDate(req.createdAt)}</TableCell>
                <TableCell>
                  {req.status === 'OPEN' && (
                    assigningId === req.id ? (
                      <div className="flex items-center gap-2">
                        <select
                          className="text-sm border rounded px-2 py-1"
                          value={selectedTech[req.id] ?? ''}
                          onChange={e => setSelectedTech(prev => ({ ...prev, [req.id]: e.target.value }))}
                        >
                          <option value="">Chọn KTV</option>
                          {technicians.map(t => (
                            <option key={t.id} value={t.id}>{t.fullName}</option>
                          ))}
                        </select>
                        <button
                          onClick={() => {
                            const techId = selectedTech[req.id]
                            if (techId) assignMutation.mutate({ id: req.id, techId })
                          }}
                          disabled={!selectedTech[req.id] || assignMutation.isPending}
                          className="text-xs bg-indigo-600 text-white px-2 py-1 rounded hover:bg-indigo-700 disabled:opacity-50"
                        >
                          Xác nhận
                        </button>
                        <button
                          onClick={() => setAssigningId(null)}
                          className="text-xs text-gray-500 hover:text-gray-700"
                        >
                          Hủy
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => setAssigningId(req.id)}
                        className="text-xs text-indigo-600 hover:underline"
                      >
                        Phân công
                      </button>
                    )
                  )}
                </TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}
    </Layout>
  )
}