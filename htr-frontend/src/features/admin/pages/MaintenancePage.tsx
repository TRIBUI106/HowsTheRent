import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { maintenanceApi, userApi } from '@/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { TableSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import type { MaintenanceRequest, User } from '@/types'

export default function AdminMaintenancePage() {
  const queryClient = useQueryClient()
  const [assigningId, setAssigningId] = useState<string | null>(null)
  const [selectedTech, setSelectedTech] = useState<Record<string, string>>({})

  const { data: requests, isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['maintenance'],
    queryFn: () => maintenanceApi.listAll(),
  })

  const { data: users } = useQuery<User[]>({
    queryKey: ['users'],
    queryFn: () => userApi.listAll(),
  })

  const technicians = users?.filter(u => u.role === 'TECHNICIAN') ?? []

  const assignMutation = useMutation({
    mutationFn: ({ id, techId }: { id: string; techId: string }) =>
      maintenanceApi.assign(id, techId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      setAssigningId(null)
    },
  })

  return (
    <Layout title="Bảo trì">
      {isLoading ? (
        <TableSkeleton rows={5} columns={7} />
      ) : (
        <Card>
          <Table headers={['Tiêu đề', 'Phòng', 'Người thuê', 'Kỹ thuật viên', 'Trạng thái', 'Ngày tạo', '']}>
            {requests?.map(req => (
              <TableRow key={req.id}>
                <TableCell className="font-medium">{req.title}</TableCell>
                <TableCell>{req.room?.roomNumber}</TableCell>
                <TableCell>{req.tenant?.fullName}</TableCell>
                <TableCell>{req.assignedTo?.fullName ?? <span className="text-fg-subtle">—</span>}</TableCell>
                <TableCell><Badge status={req.status} /></TableCell>
                <TableCell>{formatDate(req.createdAt)}</TableCell>
                <TableCell>
                  {req.status === 'OPEN' && (
                    assigningId === req.id ? (
                      <div className="flex items-center gap-2">
                        <select
                          className="text-sm border border-border/80 rounded-lg px-2 py-1 bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent"
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
                          className="text-xs bg-accent text-accent-fg px-2 py-1 rounded-lg hover:bg-accent-hover disabled:opacity-50 transition-colors"
                        >
                          Xác nhận
                        </button>
                        <button
                          onClick={() => setAssigningId(null)}
                          className="text-xs text-fg-muted hover:text-fg transition-colors"
                        >
                          Hủy
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => setAssigningId(req.id)}
                        className="text-xs text-accent hover:underline"
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
