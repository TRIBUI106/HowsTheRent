import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { formatDate } from '@/lib/utils'
import type { Notification } from '@/types'
import { CheckCheck } from 'lucide-react'

export default function TenantNotificationsPage() {
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
              className="flex items-center gap-1.5 text-sm text-indigo-600 hover:text-indigo-800 disabled:opacity-50"
            >
              <CheckCheck size={15} />
              Đánh dấu tất cả đã đọc ({unreadCount})
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="flex h-32 items-center justify-center">
            <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
          </div>
        ) : (
          <>
            {notifications?.map(n => (
              <div
                key={n.id}
                onClick={() => { if (!n.read) markOneMutation.mutate(n.id) }}
                className={`p-4 rounded-lg border cursor-pointer transition-colors ${
                  n.read ? 'bg-white hover:bg-gray-50' : 'bg-blue-50 border-blue-200 hover:bg-blue-100'
                }`}
              >
                <div className="flex justify-between items-start">
                  <div className="flex items-center gap-2">
                    {!n.read && <span className="w-2 h-2 bg-blue-500 rounded-full shrink-0" />}
                    <p className="font-medium text-gray-900">{n.title}</p>
                  </div>
                  <span className="text-xs text-gray-400 shrink-0 ml-3">{formatDate(n.createdAt)}</span>
                </div>
                <p className="text-sm text-gray-600 mt-1 ml-4">{n.body}</p>
              </div>
            ))}
            {notifications?.length === 0 && (
              <p className="text-center text-gray-400 py-8">Không có thông báo</p>
            )}
          </>
        )}
      </div>
    </Layout>
  )
}