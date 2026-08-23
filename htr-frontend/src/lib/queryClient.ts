import { QueryClient } from '@tanstack/react-query'
import { isUnauthorizedError } from '@/lib/api'

export function createAppQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: (_failureCount, error) => !isUnauthorizedError(error),
        staleTime: 1000 * 60,
        gcTime: 1000 * 60 * 60 * 24,
      },
      mutations: {
        retry: false,
      },
    },
  })
}
