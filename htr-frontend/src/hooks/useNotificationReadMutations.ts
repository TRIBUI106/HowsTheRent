import { useQueryClient } from '@tanstack/react-query'
import { notificationApi } from '@/api'
import type { Notification } from '@/types'
import { useGuardedMutation } from './useGuardedMutation'

type MutationContext = {
  previous?: Notification[]
}

const NOTIFICATIONS_QUERY_KEY = ['notifications'] as const

export function useNotificationReadMutations() {
  const queryClient = useQueryClient()

  const markOneMutation = useGuardedMutation<unknown, Error, string, MutationContext>({
    mutationFn: (id) => notificationApi.markRead(id),
    onMutate: async (id) => {
      await queryClient.cancelQueries({ queryKey: NOTIFICATIONS_QUERY_KEY })
      const previous = queryClient.getQueryData<Notification[]>(NOTIFICATIONS_QUERY_KEY)

      queryClient.setQueryData<Notification[]>(NOTIFICATIONS_QUERY_KEY, (current) =>
        current?.map((notification) =>
          notification.id === id ? { ...notification, read: true } : notification,
        ),
      )

      return { previous }
    },
    onError: (_error, _id, context) => {
      queryClient.setQueryData(NOTIFICATIONS_QUERY_KEY, context?.previous)
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_QUERY_KEY })
    },
  })

  const markAllMutation = useGuardedMutation<unknown, Error, void, MutationContext>({
    mutationFn: () => notificationApi.markAllRead(),
    onMutate: async () => {
      await queryClient.cancelQueries({ queryKey: NOTIFICATIONS_QUERY_KEY })
      const previous = queryClient.getQueryData<Notification[]>(NOTIFICATIONS_QUERY_KEY)

      queryClient.setQueryData<Notification[]>(NOTIFICATIONS_QUERY_KEY, (current) =>
        current?.map((notification) => ({ ...notification, read: true })),
      )

      return { previous }
    },
    onError: (_error, _variables, context) => {
      queryClient.setQueryData(NOTIFICATIONS_QUERY_KEY, context?.previous)
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_QUERY_KEY })
    },
  })

  return { markOneMutation, markAllMutation }
}
