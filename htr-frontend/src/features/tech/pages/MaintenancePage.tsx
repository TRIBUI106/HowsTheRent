import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import type { MaintenanceRequest } from '@/types'
import { CheckCircle } from 'lucide-react'

export default function TechMaintenancePage() {
  const queryClient = useQueryClient()

  const { data: requests, isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['tech-maintenance'],
    queryFn: () => api.get('/maintenance/assigned').then(r => r.data),
  })

  const resolveMutation = useMutation({
    mutationFn: (id: string) => api.post(`/maintenance/${id}/resolve`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['tech-maintenance'] }),
  })

  return (
    <Layout title="Công việc">
      {isLoading ? (
        <ListSkeleton items={4} />
      ) : (
        <div className="space-y-4">
          {requests?.map(req => (
            <Card key={req.id}>
              <div className="p-4">
                <div className="flex justify-between items-start">
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-fg">{req.title}</p>
                    <p className="text-sm text-fg-muted mt-1">{req.room?.roomNumber}</p>
                    {req.description && <p className="text-sm text-fg-muted mt-2">{req.description}</p>}
                    <p className="text-xs text-fg-subtle mt-3">Ngày tạo: {formatDate(req.createdAt)}</p>
                  </div>
                  <div className="flex flex-col items-end gap-3 ml-4 shrink-0">
                    <Badge status={req.status} />
                    {req.status === 'IN_PROGRESS' && (
                      <button
                        onClick={() => resolveMutation.mutate(req.id)}
                        disabled={resolveMutation.isPending}
                        className="flex items-center gap-1.5 text-xs bg-success text-success-fg px-3 py-1.5 rounded-xl hover:bg-success/90 disabled:opacity-50 transition-colors"
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
          {requests?.length === 0 && <p className="text-center text-fg-subtle py-8">Không có công việc được giao</p>}
        </div>
      )}
    </Layout>
  )
}
