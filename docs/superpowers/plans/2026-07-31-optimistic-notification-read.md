# Optimistic Notification Read State Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make notification read-state feel instant: clicking a notification or “mark all read” updates UI immediately while the backend mutation runs asynchronously.

**Architecture:** Move shared notification read mutations into a focused hook that updates the React Query `['notifications']` cache optimistically, rolls back on failure, and invalidates after settlement to sync with backend state. Replace duplicated mutation logic in admin, tenant, and technician notification pages with the shared hook.

**Tech Stack:** React 19, TypeScript, @tanstack/react-query v5, existing `notificationApi`, existing `Notification` type.

## Global Constraints

- Do not introduce new dependencies.
- Keep authentication and API behavior in the existing axios `api` client.
- Keep backend API unchanged: `POST /notifications/{id}/read` and `POST /notifications/read-all`.
- Preserve existing route/page structure for admin, tenant, and technician notifications.
- Use optimistic UI for read state and rollback/invalidate on backend failure.

---

## File Structure

- Create `htr-frontend/src/hooks/useNotificationReadMutations.ts`
  - Owns optimistic mutation logic for `markOne` and `markAll`.
  - Consumes `notificationApi` and `Notification`.
  - Produces `markOneMutation` and `markAllMutation` for page components.
- Modify `htr-frontend/src/features/admin/pages/NotificationsPage.tsx`
  - Remove duplicated `useMutation`/`useQueryClient` read-state logic.
  - Use shared hook.
- Modify `htr-frontend/src/features/tenant/pages/NotificationsPage.tsx`
  - Same as admin page.
- Modify `htr-frontend/src/features/tech/pages/NotificationsPage.tsx`
  - Same as admin page.

---

### Task 1: Add Shared Optimistic Notification Read Hook

**Files:**
- Create: `htr-frontend/src/hooks/useNotificationReadMutations.ts`

**Interfaces:**
- Consumes:
  - `notificationApi.markRead(id: string): Promise<unknown>`
  - `notificationApi.markAllRead(): Promise<unknown>`
  - query cache key `['notifications']` containing `Notification[]`
- Produces:
  - `useNotificationReadMutations(): { markOneMutation: UseMutationResult<unknown, Error, string, MutationContext>; markAllMutation: UseMutationResult<unknown, Error, void, MutationContext> }`

- [ ] **Step 1: Create the hook file**

```ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { notificationApi } from '@/api'
import type { Notification } from '@/types'

type MutationContext = {
  previous?: Notification[]
}

const NOTIFICATIONS_QUERY_KEY = ['notifications'] as const

export function useNotificationReadMutations() {
  const queryClient = useQueryClient()

  const markOneMutation = useMutation<unknown, Error, string, MutationContext>({
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

  const markAllMutation = useMutation<unknown, Error, void, MutationContext>({
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
```

- [ ] **Step 2: Run TypeScript check via frontend build**

Run: `cd htr-frontend && npm run build`

Expected: build succeeds or reports import/type issues to fix before continuing.

---

### Task 2: Replace Duplicated Notification Mutations in Role Pages

**Files:**
- Modify: `htr-frontend/src/features/admin/pages/NotificationsPage.tsx`
- Modify: `htr-frontend/src/features/tenant/pages/NotificationsPage.tsx`
- Modify: `htr-frontend/src/features/tech/pages/NotificationsPage.tsx`

**Interfaces:**
- Consumes:
  - `useNotificationReadMutations()` from Task 1
  - `markOneMutation.mutate(id: string)`
  - `markAllMutation.mutate()`
- Produces:
  - Notification cards switch to read state immediately on click.
  - “Đánh dấu tất cả đã đọc” count disappears immediately after click.

- [ ] **Step 1: Update imports in each page**

Remove:

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import api from '@/lib/api'
```

Use:

```ts
import { useQuery } from '@tanstack/react-query'
import { useNotificationReadMutations } from '@/hooks/useNotificationReadMutations'
```

Keep existing imports for `notificationApi`, `Layout`, `Notification`, and UI helpers.

- [ ] **Step 2: Replace local mutation definitions in each page**

Remove:

```ts
const queryClient = useQueryClient()

const markOneMutation = useMutation({
  mutationFn: (id: string) => api.post(`/notifications/${id}/read`),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
})

const markAllMutation = useMutation({
  mutationFn: () => api.post('/notifications/read-all'),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
})
```

Add after the `useQuery` call:

```ts
const { markOneMutation, markAllMutation } = useNotificationReadMutations()
```

- [ ] **Step 3: Keep click handlers but consume shared mutations**

The existing handlers should continue to work:

```tsx
onClick={() => { if (!n.read) markOneMutation.mutate(n.id) }}
```

```tsx
onClick={() => markAllMutation.mutate()}
```

- [ ] **Step 4: Run frontend lint and build**

Run:

```bash
cd htr-frontend
npm run lint
npm run build
```

Expected:
- lint exits 0
- build exits 0

---

## Self-Review

- Spec coverage: optimistic single notification read, optimistic mark-all, rollback on failure, backend sync after settlement, and shared admin/tenant/tech behavior are covered.
- Placeholder scan: no `TBD`, `TODO`, or unspecified implementation steps remain.
- Type consistency: hook returns `markOneMutation` and `markAllMutation`; pages consume those exact names.
