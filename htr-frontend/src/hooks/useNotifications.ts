import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { notificationApi } from '@/api/notificationApi'

export function useNotifications() {
  const qc = useQueryClient()

  const { data: notifications = [], isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: notificationApi.list,
    refetchInterval: 30_000,
  })

  const unreadCount = notifications.filter(n => !n.read).length

  const markRead = useMutation({
    mutationFn: notificationApi.markRead,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notifications'] }),
  })

  const markAllRead = useMutation({
    mutationFn: notificationApi.markAllRead,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notifications'] }),
  })

  return { notifications, isLoading, unreadCount, markRead, markAllRead }
}
