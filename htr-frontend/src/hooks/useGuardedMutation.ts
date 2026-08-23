import { useCallback } from 'react'
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

  // Depending on `mutation.mutate`/`mutation.mutateAsync` (stable across
  // renders) rather than the whole `mutation` object (which changes
  // identity whenever status/data change) is intentional: it's what keeps
  // these guarded functions referentially stable, matching native
  // `useMutation` behavior.
  const guardedMutate = useCallback(
    (...args: Parameters<typeof mutation.mutate>) =>
      guardMutate(isOnline, () => mutation.mutate(...args)),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [isOnline, mutation.mutate]
  )
  const guardedMutateAsync = useCallback(
    (...args: Parameters<typeof mutation.mutateAsync>) =>
      guardMutateAsync(isOnline, () => mutation.mutateAsync(...args)),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [isOnline, mutation.mutateAsync]
  )

  return {
    ...mutation,
    mutate: guardedMutate,
    mutateAsync: guardedMutateAsync,
  }
}
