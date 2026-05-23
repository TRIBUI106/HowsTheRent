import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import type { Notification } from '@/types'
import { CheckCheck } from 'lucide-react'

export default function TechNotificationsPage() {
  const queryClient = useQueryClient()

  const { data: notifications, isLoading } = useQuery<Notification[]>({
    queryKey: ['notifications'],
    queryFn: () => api.get('/notifications').then(r => r.data),
  })

  const markOneMutation = useMutation({
    mutationFn: (id: string) => api.post(`/notifications/${id}/read`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
  })

  const markAllMutation = useMutation({
    mutationFn: () => api.post('/notifications/read-all'),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
  })

  const unreadCount = notifications?.filter(n => !n.read).length ?? 0

  return (
    <Layout title="Thông báo">
      <div className="space-y-3">
        {!isLoading && unreadCount > 0 && (
          <div className="flex justify-end">
            <button
              onClick={() => markAllMutation.mutate()}
              disabled={markAllMutation.isPending}
              className="flex items-center gap-1.5 text-sm text-accent hover:text-accent-hover disabled:opacity-50 transition-colors"
            >
              <CheckCheck size={15} />
              Đánh dấu tất cả đã đọc ({unreadCount})
            </button>
          </div>
        )}

        {isLoading ? (
          <ListSkeleton items={5} />
        ) : (
          <>
            {notifications?.map(n => (
              <div
                key={n.id}
                onClick={() => { if (!n.read) markOneMutation.mutate(n.id) }}
                className={`p-4 rounded-xl border cursor-pointer transition-colors ${
                  n.read ? 'bg-surface border-border/80 hover:bg-sidebar/50' : 'bg-accent-surface border-accent/20 hover:bg-accent-surface/80'
                }`}
              >
                <div className="flex justify-between items-start">
                  <div className="flex items-center gap-2">
                    {!n.read && <span className="w-2 h-2 bg-accent rounded-full shrink-0" />}
                    <p className="font-medium text-fg">{n.title}</p>
                  </div>
                  <span className="text-xs text-fg-subtle shrink-0 ml-3">{formatDate(n.createdAt)}</span>
                </div>
                <p className="text-sm text-fg-muted mt-1 ml-4">{n.body}</p>
              </div>
            ))}
            {notifications?.length === 0 && (
              <p className="text-center text-fg-subtle py-8">Không có thông báo</p>
            )}
          </>
        )}
      </div>
    </Layout>
  )
}
