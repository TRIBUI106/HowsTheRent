import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { maintenanceApi, userApi } from '@/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableCell, TableRow } from '@/components/ui/table'
import { TableSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { MaintenanceRequest, User } from '@/types'

export default function AdminMaintenancePage() {
  const queryClient = useQueryClient()
  const [assigningId, setAssigningId] = useState<string | null>(null)
  const [selectedTech, setSelectedTech] = useState<Record<string, string>>({})

  const { data: requests = [], isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['maintenance'],
    queryFn: () => maintenanceApi.listAll(),
  })

  const { data: users } = useQuery<User[]>({
    queryKey: ['users'],
    queryFn: () => userApi.listAll(),
  })

  const technicians = users?.filter((user) => user.role === 'TECHNICIAN') ?? []

  const assignMutation = useMutation({
    mutationFn: ({ id, techId }: { id: string; techId: string }) => maintenanceApi.assign(id, techId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã phân công kỹ thuật viên', type: 'success' })
      setAssigningId(null)
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể phân công kỹ thuật viên',
        type: 'error',
      })
    },
  })

  return (
    <Layout title="Bảo trì">
      {isLoading ? (
        <TableSkeleton rows={5} columns={7} />
      ) : (
        <Card>
          <Table headers={['Tiêu đề', 'Phòng', 'Người thuê', 'Kỹ thuật viên', 'Trạng thái', 'Ngày tạo', '']}>
            {requests.map((request) => (
              <TableRow key={request.id}>
                <TableCell className="font-medium">{request.title}</TableCell>
                <TableCell>{request.room?.roomNumber || '-'}</TableCell>
                <TableCell>{request.tenant?.fullName || '-'}</TableCell>
                <TableCell>{request.assignedTo?.fullName ?? <span className="text-fg-subtle">—</span>}</TableCell>
                <TableCell><Badge status={request.status} /></TableCell>
                <TableCell>{formatDate(request.createdAt)}</TableCell>
                <TableCell>
                  {request.status === 'OPEN' && (
                    assigningId === request.id ? (
                      <div className="flex items-center gap-2">
                        <select
                          className="rounded-lg border border-border/80 bg-surface px-2 py-1 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                          value={selectedTech[request.id] ?? ''}
                          onChange={(event) => setSelectedTech((previous) => ({ ...previous, [request.id]: event.target.value }))}
                        >
                          <option value="">Chọn KTV</option>
                          {technicians.map((technician) => (
                            <option key={technician.id} value={technician.id}>{technician.fullName}</option>
                          ))}
                        </select>
                        <button
                          onClick={() => {
                            const techId = selectedTech[request.id]
                            if (techId) assignMutation.mutate({ id: request.id, techId })
                          }}
                          disabled={!selectedTech[request.id] || assignMutation.isPending}
                          className="rounded-lg bg-accent px-2 py-1 text-xs text-accent-fg transition-colors hover:bg-accent-hover disabled:opacity-50"
                        >
                          Xác nhận
                        </button>
                        <button
                          onClick={() => setAssigningId(null)}
                          className="text-xs text-fg-muted transition-colors hover:text-fg"
                        >
                          Hủy
                        </button>
                      </div>
                    ) : (
                      <button onClick={() => setAssigningId(request.id)} className="text-xs text-accent hover:underline">
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
