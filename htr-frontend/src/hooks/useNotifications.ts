import { useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { notificationApi } from '@/api/notificationApi'
import { showToast } from '@/lib/toast'

export function useNotifications() {
  const qc = useQueryClient()

  const { data: notifications = [], isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: notificationApi.list,
    refetchInterval: 30_000,
  })

  const unreadCount = notifications.filter(n => !n.read).length

  useEffect(() => {
    const apiBase = import.meta.env.VITE_API_URL || '/api'
    const stream = new EventSource(`${apiBase}/notifications/stream`, { withCredentials: true })
    stream.addEventListener('notification', (event) => {
      try {
        const notification = JSON.parse((event as MessageEvent).data)
        showToast({
          message: `${notification.title}: ${notification.body}`,
          type: 'info',
        })
        if (notification.type === 'MAINTENANCE') {
          qc.invalidateQueries({ queryKey: ['tech-maintenance'] })
          qc.invalidateQueries({ queryKey: ['tenant-maintenance'] })
          qc.invalidateQueries({ queryKey: ['maintenance'] })
          qc.invalidateQueries({ queryKey: ['dashboard'] })
        }
      } finally {
        qc.invalidateQueries({ queryKey: ['notifications'] })
      }
    })
    return () => stream.close()
  }, [qc])

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
