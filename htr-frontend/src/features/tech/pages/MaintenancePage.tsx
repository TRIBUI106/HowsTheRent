import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CheckCircle } from 'lucide-react'
import { maintenanceApi } from '@/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import type { MaintenanceRequest } from '@/types'

export default function TechMaintenancePage() {
  const queryClient = useQueryClient()

  const { data: requests = [], isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tech-maintenance'],
    queryFn: () => maintenanceApi.listAssigned(),
  })

  const resolveMutation = useMutation({
    mutationFn: (id: string) => maintenanceApi.resolve(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['maintenance'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      showToast({ message: 'Đã hoàn thành yêu cầu bảo trì', type: 'success' })
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể cập nhật trạng thái',
        type: 'error',
      })
    },
  })

  return (
    <Layout title="Công việc">
      {isLoading ? (
        <ListSkeleton items={4} />
      ) : (
        <div className="space-y-4">
          {requests.map((request) => (
            <Card key={request.id}>
              <div className="p-4">
                <div className="flex items-start justify-between">
                  <div className="min-w-0 flex-1">
                    <p className="font-medium text-fg">{request.title}</p>
                    <p className="mt-1 text-sm text-fg-muted">{request.room?.roomNumber || '-'}</p>
                    {request.description && <p className="mt-2 text-sm text-fg-muted">{request.description}</p>}
                    <p className="mt-3 text-xs text-fg-subtle">Ngày tạo: {formatDate(request.createdAt)}</p>
                  </div>

                  <div className="ml-4 flex shrink-0 flex-col items-end gap-3">
                    <Badge status={request.status} />
                    {request.status === 'IN_PROGRESS' && (
                      <button
                        onClick={() => resolveMutation.mutate(request.id)}
                        disabled={resolveMutation.isPending}
                        className="flex items-center gap-1.5 rounded-xl bg-success px-3 py-1.5 text-xs text-success-fg transition-colors hover:bg-success/90 disabled:opacity-50"
                      >
                        <CheckCircle size={13} />
                        Hoàn thành
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </Card>
          ))}

          {requests.length === 0 && (
            <p className="py-8 text-center text-fg-subtle">Không có công việc được giao</p>
          )}
        </div>
      )}
    </Layout>
  )
}
