import {
  useMutation,
  type UseMutationOptions,
  type UseMutationResult,
} from '@tanstack/react-query'
import { useOnlineStatus } from './useOnlineStatus'
import { guardMutate, guardMutateAsync } from '@/lib/mutationGuard'

export function useGuardedMutation<
  TData = unknown,
  TError = unknown,
  TVariables = void,
  TContext = unknown,
>(
  options: UseMutationOptions<TData, TError, TVariables, TContext>
): UseMutationResult<TData, TError, TVariables, TContext> {
  const isOnline = useOnlineStatus()
  const mutation = useMutation(options)

  return {
    ...mutation,
    mutate: (...args) => guardMutate(isOnline, () => mutation.mutate(...args)),
    mutateAsync: (...args) =>
      guardMutateAsync(isOnline, () => mutation.mutateAsync(...args)),
  }
}
