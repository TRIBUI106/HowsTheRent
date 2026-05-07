import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { formatDate } from '@/lib/utils'
import type { Notification } from '@/types'

export default function TechNotificationsPage() {
  const { data: notifications, isLoading } = useQuery<Notification[]>({
    queryKey: ['notifications'],
    queryFn: () => api.get('/notifications').then(r => r.data),
  })

  return (
    <Layout title="Thông báo">
      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
        </div>
      ) : (
        <div className="space-y-3">
          {notifications?.map(n => (
            <div key={n.id} className={`p-4 rounded-lg border ${n.read ? 'bg-white' : 'bg-blue-50 border-blue-200'}`}>
              <div className="flex justify-between">
                <p className="font-medium text-gray-900">{n.title}</p>
                <span className="text-xs text-gray-400">{formatDate(n.createdAt)}</span>
              </div>
              <p className="text-sm text-gray-600 mt-1">{n.body}</p>
            </div>
          ))}
          {notifications?.length === 0 && <p className="text-center text-gray-400 py-8">Không có thông báo</p>}
        </div>
      )}
    </Layout>
  )
}