# Frontend Query Cache Persistence & Offline Read Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the React Query cache to `localStorage` across reloads for all roles, reduce redundant refetches for near-static reference data, and block (not queue) write actions while offline, with a visible offline indicator.

**Architecture:** Extend the existing `QueryClient` (no new caching system) with `@tanstack/react-query-persist-client` + `@tanstack/query-sync-storage-persister`. Add a small network-awareness layer (`useOnlineStatus`) and a drop-in `useGuardedMutation` hook that wraps `useMutation` so existing call sites (`xMutation.mutate(...)`) need zero changes — only their declaration line swaps from `useMutation` to `useGuardedMutation`.

**Tech Stack:** React 19, TypeScript, Vite, `@tanstack/react-query` v5, Zustand, Vitest + `@testing-library/react`, npm.

**Spec:** `docs/superpowers/specs/2026-08-23-frontend-query-cache-persistence-design.md`

## Global Constraints

- No mutation queueing or background sync — offline writes are blocked with a toast, never deferred. (Spec: Goals, Non-goals)
- Persisted cache is not tiered by data sensitivity — everything persists the same way. (Spec: Goals, Non-goals)
- No new dependency for a service worker / PWA install flow in this plan. (Spec: Non-goals)
- No changes to `api/*.ts` files or the existing inline `useQuery({...})` call pattern — no query-key factory is introduced. (Spec: Architecture)
- Offline toast/banner copy must state that data may not be current — never silently present cached data as live. (Spec: Error handling)
- Cache must be cleared on logout via `persister.removeClient()`. (Spec: Data flow, step 6)
- Persisted cache must be discarded (not partially loaded) when the app's cache-buster value changes. (Spec: Data flow, step 7)
- `localStorage` unavailable/full must degrade to no-persistence, never crash the app. (Spec: Error handling)

---

## File Structure

```
src/lib/queryClient.ts          (new)  QueryClient factory, extracted from main.tsx
src/lib/persister.ts            (new)  localStorage persister + buster + fallback
src/lib/mutationGuard.ts        (new)  guardMutate / guardMutateAsync helpers
src/hooks/useOnlineStatus.ts    (new)  online/offline boolean hook
src/hooks/useGuardedMutation.ts (new)  useMutation wrapper enforcing the guard
src/components/OfflineBanner.tsx(new)  global offline indicator
src/main.tsx                    (modify) wire PersistQueryClientProvider
src/App.tsx                     (modify) mount OfflineBanner
src/stores/authStore.ts         (modify) clear persisted cache on logout
15 page/hook files              (modify) useMutation -> useGuardedMutation (mechanical)
```

---

### Task 1: `lib/queryClient.ts` — QueryClient factory

**Files:**
- Create: `src/lib/queryClient.ts`
- Test: `src/lib/queryClient.test.ts`

**Interfaces:**
- Produces: `createAppQueryClient(): QueryClient` — same `defaultOptions` currently inline in `main.tsx` (`retry` skips on `isUnauthorizedError`, query `staleTime: 1000 * 60`, mutation `retry: false`).

- [ ] **Step 1: Write the failing test**

```typescript
// src/lib/queryClient.test.ts
import { describe, it, expect } from 'vitest'
import { createAppQueryClient } from './queryClient'

describe('createAppQueryClient', () => {
  it('sets a 60s default staleTime for queries', () => {
    const client = createAppQueryClient()
    expect(client.getDefaultOptions().queries?.staleTime).toBe(1000 * 60)
  })

  it('disables retry for mutations', () => {
    const client = createAppQueryClient()
    expect(client.getDefaultOptions().mutations?.retry).toBe(false)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:unit -- src/lib/queryClient.test.ts`
Expected: FAIL — `createAppQueryClient` is not defined / module has no export.

- [ ] **Step 3: Write minimal implementation**

```typescript
// src/lib/queryClient.ts
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test:unit -- src/lib/queryClient.test.ts`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add src/lib/queryClient.ts src/lib/queryClient.test.ts
git commit -m "feat: extract QueryClient factory with 24h gcTime for persistence"
```

---

### Task 2: `lib/mutationGuard.ts` — offline write guard helpers

**Files:**
- Create: `src/lib/mutationGuard.ts`
- Test: `src/lib/mutationGuard.test.ts`

**Interfaces:**
- Consumes: `showToast` from `src/lib/toast.ts` (existing, signature `showToast({ message, type?, durationMs? })`).
- Produces: `guardMutate(isOnline: boolean, run: () => void): void` and `guardMutateAsync<T>(isOnline: boolean, run: () => Promise<T>): Promise<T>` — used by Task 4's `useGuardedMutation`.

- [ ] **Step 1: Write the failing test**

```typescript
// src/lib/mutationGuard.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { guardMutate, guardMutateAsync } from './mutationGuard'
import { showToast } from './toast'

vi.mock('./toast', () => ({ showToast: vi.fn() }))

describe('guardMutate', () => {
  beforeEach(() => vi.mocked(showToast).mockClear())

  it('runs the callback when online', () => {
    const run = vi.fn()
    guardMutate(true, run)
    expect(run).toHaveBeenCalledOnce()
    expect(showToast).not.toHaveBeenCalled()
  })

  it('blocks and toasts when offline', () => {
    const run = vi.fn()
    guardMutate(false, run)
    expect(run).not.toHaveBeenCalled()
    expect(showToast).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'error' })
    )
  })
})

describe('guardMutateAsync', () => {
  beforeEach(() => vi.mocked(showToast).mockClear())

  it('resolves the callback result when online', async () => {
    const run = vi.fn().mockResolvedValue('ok')
    await expect(guardMutateAsync(true, run)).resolves.toBe('ok')
    expect(run).toHaveBeenCalledOnce()
  })

  it('rejects without calling the callback when offline', async () => {
    const run = vi.fn()
    await expect(guardMutateAsync(false, run)).rejects.toThrow()
    expect(run).not.toHaveBeenCalled()
    expect(showToast).toHaveBeenCalledOnce()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:unit -- src/lib/mutationGuard.test.ts`
Expected: FAIL — module `./mutationGuard` not found.

- [ ] **Step 3: Write minimal implementation**

```typescript
// src/lib/mutationGuard.ts
import { showToast } from './toast'

export const OFFLINE_WRITE_MESSAGE =
  'Không có kết nối mạng, thao tác này cần mạng để thực hiện.'

export function guardMutate(isOnline: boolean, run: () => void): void {
  if (!isOnline) {
    showToast({ message: OFFLINE_WRITE_MESSAGE, type: 'error' })
    return
  }
  run()
}

export function guardMutateAsync<T>(
  isOnline: boolean,
  run: () => Promise<T>
): Promise<T> {
  if (!isOnline) {
    showToast({ message: OFFLINE_WRITE_MESSAGE, type: 'error' })
    return Promise.reject(new Error('offline'))
  }
  return run()
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test:unit -- src/lib/mutationGuard.test.ts`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add src/lib/mutationGuard.ts src/lib/mutationGuard.test.ts
git commit -m "feat: add guardMutate/guardMutateAsync offline-write helpers"
```

---

### Task 3: `hooks/useOnlineStatus.ts` — network status hook

**Files:**
- Create: `src/hooks/useOnlineStatus.ts`
- Test: `src/hooks/useOnlineStatus.test.ts`

**Interfaces:**
- Produces: `useOnlineStatus(): boolean` — initial value from `navigator.onLine`, updates on `window` `online`/`offline` events. Consumed by Task 4 (`useGuardedMutation`) and Task 5 (`OfflineBanner`).

- [ ] **Step 1: Write the failing test**

```typescript
// src/hooks/useOnlineStatus.test.ts
import { describe, it, expect, afterEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useOnlineStatus } from './useOnlineStatus'

describe('useOnlineStatus', () => {
  afterEach(() => {
    Object.defineProperty(window.navigator, 'onLine', {
      value: true,
      configurable: true,
    })
  })

  it('starts as true when navigator.onLine is true', () => {
    const { result } = renderHook(() => useOnlineStatus())
    expect(result.current).toBe(true)
  })

  it('flips to false on the offline event', () => {
    const { result } = renderHook(() => useOnlineStatus())
    act(() => {
      window.dispatchEvent(new Event('offline'))
    })
    expect(result.current).toBe(false)
  })

  it('flips back to true on the online event', () => {
    const { result } = renderHook(() => useOnlineStatus())
    act(() => {
      window.dispatchEvent(new Event('offline'))
    })
    act(() => {
      window.dispatchEvent(new Event('online'))
    })
    expect(result.current).toBe(true)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:unit -- src/hooks/useOnlineStatus.test.ts`
Expected: FAIL — module `./useOnlineStatus` not found.

- [ ] **Step 3: Write minimal implementation**

```typescript
// src/hooks/useOnlineStatus.ts
import { useEffect, useState } from 'react'

export function useOnlineStatus(): boolean {
  const [isOnline, setIsOnline] = useState(() => navigator.onLine)

  useEffect(() => {
    const goOnline = () => setIsOnline(true)
    const goOffline = () => setIsOnline(false)
    window.addEventListener('online', goOnline)
    window.addEventListener('offline', goOffline)
    return () => {
      window.removeEventListener('online', goOnline)
      window.removeEventListener('offline', goOffline)
    }
  }, [])

  return isOnline
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test:unit -- src/hooks/useOnlineStatus.test.ts`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add src/hooks/useOnlineStatus.ts src/hooks/useOnlineStatus.test.ts
git commit -m "feat: add useOnlineStatus hook"
```

---

### Task 4: `hooks/useGuardedMutation.ts` — drop-in guarded useMutation

**Files:**
- Create: `src/hooks/useGuardedMutation.ts`
- Test: `src/hooks/useGuardedMutation.test.ts`

**Interfaces:**
- Consumes: `useOnlineStatus()` (Task 3), `guardMutate`/`guardMutateAsync` (Task 2), `useMutation`/`UseMutationOptions`/`UseMutationResult` from `@tanstack/react-query`.
- Produces: `useGuardedMutation<TData, TError, TVariables, TContext>(options): UseMutationResult<TData, TError, TVariables, TContext>` — identical return shape to `useMutation`, so existing call sites (`xMutation.mutate(...)`, `xMutation.isPending`, etc.) work unchanged. This is the hook every migration task (6-16) will swap in.

- [ ] **Step 1: Write the failing test**

```typescript
// src/hooks/useGuardedMutation.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, act, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import type { ReactNode } from 'react'
import { useGuardedMutation } from './useGuardedMutation'
import { showToast } from '@/lib/toast'

vi.mock('@/lib/toast', () => ({ showToast: vi.fn() }))

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient()
  return (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  )
}

describe('useGuardedMutation', () => {
  beforeEach(() => {
    vi.mocked(showToast).mockClear()
    Object.defineProperty(window.navigator, 'onLine', {
      value: true,
      configurable: true,
    })
  })

  it('calls through to mutationFn when online', async () => {
    const mutationFn = vi.fn().mockResolvedValue('ok')
    const { result } = renderHook(
      () => useGuardedMutation({ mutationFn }),
      { wrapper }
    )
    act(() => result.current.mutate(undefined))
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(mutationFn).toHaveBeenCalledOnce()
  })

  it('blocks mutate and toasts when offline', async () => {
    Object.defineProperty(window.navigator, 'onLine', {
      value: false,
      configurable: true,
    })
    const mutationFn = vi.fn().mockResolvedValue('ok')
    const { result } = renderHook(
      () => useGuardedMutation({ mutationFn }),
      { wrapper }
    )
    act(() => result.current.mutate(undefined))
    expect(mutationFn).not.toHaveBeenCalled()
    expect(showToast).toHaveBeenCalledOnce()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:unit -- src/hooks/useGuardedMutation.test.ts`
Expected: FAIL — module `./useGuardedMutation` not found.

- [ ] **Step 3: Write minimal implementation**

```typescript
// src/hooks/useGuardedMutation.ts
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test:unit -- src/hooks/useGuardedMutation.test.ts`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add src/hooks/useGuardedMutation.ts src/hooks/useGuardedMutation.test.ts
git commit -m "feat: add useGuardedMutation drop-in wrapper for offline write blocking"
```

---

### Task 5: `components/OfflineBanner.tsx` — global offline indicator

**Files:**
- Create: `src/components/OfflineBanner.tsx`
- Test: `src/components/OfflineBanner.test.tsx`
- Modify: `src/App.tsx`

**Interfaces:**
- Consumes: `useOnlineStatus()` (Task 3).
- Produces: `<OfflineBanner />` — renders `null` when online, a fixed banner with Vietnamese copy when offline. Mounted once in `App.tsx` so it's visible across all routes.

- [ ] **Step 1: Write the failing test**

```typescript
// src/components/OfflineBanner.test.tsx
import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, act } from '@testing-library/react'
import OfflineBanner from './OfflineBanner'

describe('OfflineBanner', () => {
  afterEach(() => {
    Object.defineProperty(window.navigator, 'onLine', {
      value: true,
      configurable: true,
    })
  })

  it('renders nothing while online', () => {
    render(<OfflineBanner />)
    expect(screen.queryByText(/không có kết nối mạng/i)).toBeNull()
  })

  it('shows the banner when offline', () => {
    render(<OfflineBanner />)
    act(() => {
      window.dispatchEvent(new Event('offline'))
    })
    expect(screen.getByText(/không có kết nối mạng/i)).toBeInTheDocument()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:unit -- src/components/OfflineBanner.test.tsx`
Expected: FAIL — module `./OfflineBanner` not found.

- [ ] **Step 3: Write minimal implementation**

```typescript
// src/components/OfflineBanner.tsx
import { useOnlineStatus } from '@/hooks/useOnlineStatus'

export default function OfflineBanner() {
  const isOnline = useOnlineStatus()

  if (isOnline) return null

  return (
    <div className="fixed inset-x-0 top-0 z-50 bg-amber-500 px-4 py-2 text-center text-sm font-medium text-white">
      Không có kết nối mạng. Dữ liệu hiển thị có thể chưa cập nhật mới nhất
      và các thao tác chỉnh sửa tạm thời bị tắt.
    </div>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test:unit -- src/components/OfflineBanner.test.tsx`
Expected: PASS (2 tests)

- [ ] **Step 5: Mount in App shell**

In `src/App.tsx`, add the import and render `<OfflineBanner />` once per return branch, outside the `Routes` so it's visible on every route including the logged-out landing/login pages. Apply this exact diff:

```diff
 import { Routes, Route, Navigate } from 'react-router-dom'
 import { useAuthStore } from '@/stores/authStore'
+import OfflineBanner from '@/components/OfflineBanner'
 import LandingPage from '@/pages/LandingPage'
 import LoginPage from '@/features/auth/pages/LoginPage'
 import ForgotPasswordPage from '@/features/auth/pages/ForgotPasswordPage'
 import ResetPasswordPage from '@/features/auth/pages/ResetPasswordPage'
 import ChangePasswordPage from '@/features/auth/pages/ChangePasswordPage'
 import ProfilePage from '@/features/auth/pages/ProfilePage'
 import PaymentSuccessPage from '@/features/payment/pages/SuccessPage'
 import PaymentCancelPage from '@/features/payment/pages/CancelPage'
 import NotFoundPage from '@/pages/NotFoundPage'
 import adminRoutes from '@/router/adminRoutes'
 import tenantRoutes from '@/router/tenantRoutes'
 import techRoutes from '@/router/techRoutes'

 export default function App() {
   const { user } = useAuthStore()

   if (!user) {
     return (
-      <Routes>
-        <Route path="/" element={<LandingPage />} />
-        <Route path="/landing" element={<LandingPage />} />
-        <Route path="/login" element={<LoginPage />} />
-        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
-        <Route path="/reset-password" element={<ResetPasswordPage />} />
-        <Route path="/payment/success" element={<PaymentSuccessPage />} />
-        <Route path="/payment/cancel" element={<PaymentCancelPage />} />
-        <Route path="*" element={<Navigate to="/login" replace />} />
-      </Routes>
+      <>
+        <OfflineBanner />
+        <Routes>
+          <Route path="/" element={<LandingPage />} />
+          <Route path="/landing" element={<LandingPage />} />
+          <Route path="/login" element={<LoginPage />} />
+          <Route path="/forgot-password" element={<ForgotPasswordPage />} />
+          <Route path="/reset-password" element={<ResetPasswordPage />} />
+          <Route path="/payment/success" element={<PaymentSuccessPage />} />
+          <Route path="/payment/cancel" element={<PaymentCancelPage />} />
+          <Route path="*" element={<Navigate to="/login" replace />} />
+        </Routes>
+      </>
     )
   }

   const homePath =
     ['ADMIN', 'PLATFORM_ADMIN', 'LANDLORD_ADMIN'].includes(user.role) ? '/admin' :
     user?.role === 'TENANT' ? '/tenant' :
     '/tech'

   return (
-    <Routes>
-      <Route path="/" element={<Navigate to={homePath} replace />} />
-      <Route path="/login" element={<Navigate to={homePath} replace />} />
-      <Route path="/landing" element={<LandingPage />} />
-      <Route path="/change-password" element={<ChangePasswordPage />} />
-      <Route path="/profile" element={<ProfilePage />} />
-      {adminRoutes}
-      {tenantRoutes}
-      {techRoutes}
-      <Route path="/payment/success" element={<PaymentSuccessPage />} />
-      <Route path="/payment/cancel" element={<PaymentCancelPage />} />
-      <Route path="*" element={<NotFoundPage />} />
-    </Routes>
+    <>
+      <OfflineBanner />
+      <Routes>
+        <Route path="/" element={<Navigate to={homePath} replace />} />
+        <Route path="/login" element={<Navigate to={homePath} replace />} />
+        <Route path="/landing" element={<LandingPage />} />
+        <Route path="/change-password" element={<ChangePasswordPage />} />
+        <Route path="/profile" element={<ProfilePage />} />
+        {adminRoutes}
+        {tenantRoutes}
+        {techRoutes}
+        <Route path="/payment/success" element={<PaymentSuccessPage />} />
+        <Route path="/payment/cancel" element={<PaymentCancelPage />} />
+        <Route path="*" element={<NotFoundPage />} />
+      </Routes>
+    </>
   )
 }
```

- [ ] **Step 6: Verify build**

Run: `npm run build`
Expected: TypeScript build succeeds, no errors.

- [ ] **Step 7: Commit**

```bash
git add src/components/OfflineBanner.tsx src/components/OfflineBanner.test.tsx src/App.tsx
git commit -m "feat: add global OfflineBanner mounted in App shell"
```

---

### Task 6: `lib/persister.ts` — localStorage persister with fallback

**Files:**
- Create: `src/lib/persister.ts`
- Test: `src/lib/persister.test.ts`
- Modify: `htr-frontend/package.json` (new dependencies)

**Interfaces:**
- Produces: `getPersister(): Persister | null` (returns `null` if `localStorage` is unavailable), `CACHE_BUSTER: string`, `removePersistedCache(): void`. Consumed by Task 7 (`main.tsx` wiring) and Task 9 (`authStore.ts` logout).

- [ ] **Step 1: Install dependencies**

```bash
cd htr-frontend
npm install @tanstack/react-query-persist-client@^5 @tanstack/query-sync-storage-persister@^5
```

- [ ] **Step 2: Write the failing test**

```typescript
// src/lib/persister.test.ts
import { describe, it, expect, vi, afterEach } from 'vitest'
import { getPersister, removePersistedCache, CACHE_BUSTER } from './persister'

describe('getPersister', () => {
  it('returns a persister backed by localStorage', () => {
    const persister = getPersister()
    expect(persister).not.toBeNull()
    expect(typeof persister?.persistClient).toBe('function')
  })

  it('returns null and does not throw when localStorage.setItem throws', () => {
    const original = window.localStorage.setItem
    vi.spyOn(window.localStorage.__proto__, 'setItem').mockImplementation(() => {
      throw new Error('quota exceeded')
    })
    expect(() => getPersister()).not.toThrow()
    expect(getPersister()).toBeNull()
    window.localStorage.setItem = original
    vi.restoreAllMocks()
  })
})

describe('CACHE_BUSTER', () => {
  it('is a non-empty string', () => {
    expect(typeof CACHE_BUSTER).toBe('string')
    expect(CACHE_BUSTER.length).toBeGreaterThan(0)
  })
})

describe('removePersistedCache', () => {
  it('does not throw when called', () => {
    expect(() => removePersistedCache()).not.toThrow()
  })
})
```

- [ ] **Step 3: Run test to verify it fails**

Run: `npm run test:unit -- src/lib/persister.test.ts`
Expected: FAIL — module `./persister` not found.

- [ ] **Step 4: Write minimal implementation**

```typescript
// src/lib/persister.ts
import { createSyncStoragePersister } from '@tanstack/query-sync-storage-persister'
import type { Persister } from '@tanstack/react-query-persist-client'

export const CACHE_BUSTER = 'v1'
const STORAGE_KEY = 'htr-query-cache'

export function getPersister(): Persister | null {
  try {
    return createSyncStoragePersister({
      storage: window.localStorage,
      key: STORAGE_KEY,
    })
  } catch (error) {
    console.warn('React Query persistence disabled (localStorage unavailable):', error)
    return null
  }
}

export function removePersistedCache(): void {
  try {
    window.localStorage.removeItem(STORAGE_KEY)
  } catch (error) {
    console.warn('Failed to clear persisted query cache:', error)
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `npm run test:unit -- src/lib/persister.test.ts`
Expected: PASS (4 tests)

- [ ] **Step 6: Commit**

```bash
git add htr-frontend/package.json htr-frontend/package-lock.json src/lib/persister.ts src/lib/persister.test.ts
git commit -m "feat: add localStorage query cache persister with fallback"
```

---

### Task 7: Wire `main.tsx` — `PersistQueryClientProvider`

**Files:**
- Modify: `src/main.tsx`

**Interfaces:**
- Consumes: `createAppQueryClient` (Task 1), `getPersister`, `CACHE_BUSTER` (Task 6).

- [ ] **Step 1: Replace the inline QueryClient and provider**

```diff
 import { StrictMode } from 'react'
 import { createRoot } from 'react-dom/client'
-import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
+import { QueryClientProvider } from '@tanstack/react-query'
+import { PersistQueryClientProvider } from '@tanstack/react-query-persist-client'
 import { BrowserRouter } from 'react-router-dom'
-import { isUnauthorizedError } from '@/lib/api'
+import { createAppQueryClient } from '@/lib/queryClient'
+import { getPersister, CACHE_BUSTER } from '@/lib/persister'
 import App from './App'
 import ToastViewport from '@/components/ToastViewport'
 import './index.css'

-const queryClient = new QueryClient({
-  defaultOptions: {
-    queries: {
-      retry: (_failureCount, error) => !isUnauthorizedError(error),
-      staleTime: 1000 * 60,
-    },
-    mutations: {
-      retry: false,
-    },
-  },
-})
+const queryClient = createAppQueryClient()
+const persister = getPersister()

 createRoot(document.getElementById('root')!).render(
   <StrictMode>
     <BrowserRouter>
-      <QueryClientProvider client={queryClient}>
-        <App />
-        <ToastViewport />
-      </QueryClientProvider>
+      {persister ? (
+        <PersistQueryClientProvider
+          client={queryClient}
+          persistOptions={{ persister, buster: CACHE_BUSTER }}
+        >
+          <App />
+          <ToastViewport />
+        </PersistQueryClientProvider>
+      ) : (
+        <QueryClientProvider client={queryClient}>
+          <App />
+          <ToastViewport />
+        </QueryClientProvider>
+      )}
     </BrowserRouter>
   </StrictMode>,
 )
```

Both `QueryClientProvider` (fallback branch) and `PersistQueryClientProvider` (normal branch) are imported and used — `isUnauthorizedError` is no longer imported directly in this file since its usage moved into `createAppQueryClient` (Task 1).

- [ ] **Step 2: Verify build**

Run: `npm run build`
Expected: TypeScript build succeeds, no errors.

- [ ] **Step 3: Manual verification**

Run: `npm run dev`, open the app, log in, navigate to a data-heavy page (e.g. `/admin/properties`) so it populates the cache, then reload the page with DevTools Network tab open. Expected: page content appears immediately from cache (no loading spinner flash) while a background revalidation request fires.

- [ ] **Step 4: Commit**

```bash
git add src/main.tsx
git commit -m "feat: wire PersistQueryClientProvider into app root"
```

---

### Task 8: Reference-data `staleTime` overrides

**Files:**
- Modify: `src/features/admin/pages/PropertiesPage.tsx:54-57`
- Modify: `src/features/admin/pages/SlaConfigPage.tsx:22-25`
- Modify: `src/features/admin/pages/FeeConfigPage.tsx:38-42`

**Interfaces:**
- None — purely `useQuery` option changes, no new exports.

- [ ] **Step 1: `property-types` — rarely changes, override to 10 minutes**

In `src/features/admin/pages/PropertiesPage.tsx`, change lines 54-57:

```diff
   const { data: propertyTypes = [] } = useQuery<PropertyType[]>({
     queryKey: ['property-types'],
     queryFn: () => propertyTypeApi.list(),
+    staleTime: 1000 * 60 * 10,
   })
```

- [ ] **Step 2: `sla-rules` — rarely changes, override to 10 minutes**

In `src/features/admin/pages/SlaConfigPage.tsx`, change lines 22-25:

```diff
   const { data: rules = [], isLoading } = useQuery<SlaRule[]>({
     queryKey: ['sla-rules'],
     queryFn: slaApi.listRules,
+    staleTime: 1000 * 60 * 10,
   })
```

- [ ] **Step 3: `fee-config` — rarely changes, override to 10 minutes**

In `src/features/admin/pages/FeeConfigPage.tsx`, change lines 38-42:

```diff
   const { data: feeConfig, isLoading: feeLoading } = useQuery<FeeConfig>({
     queryKey: ['fee-config', selectedProp],
     queryFn: () => api.get(`/properties/${selectedProp}/fee-config`).then(r => r.data),
     enabled: !!selectedProp,
+    staleTime: 1000 * 60 * 10,
   })
```

- [ ] **Step 4: Verify build**

Run: `npm run build`
Expected: TypeScript build succeeds, no errors.

- [ ] **Step 5: Commit**

```bash
git add src/features/admin/pages/PropertiesPage.tsx src/features/admin/pages/SlaConfigPage.tsx src/features/admin/pages/FeeConfigPage.tsx
git commit -m "perf: raise staleTime for near-static reference-data queries"
```

---

### Task 9: Wire `authStore.ts` — clear persisted cache on logout

**Files:**
- Modify: `src/stores/authStore.ts`
- Test: `src/stores/authStore.test.ts`

**Interfaces:**
- Consumes: `removePersistedCache` (Task 6).

This single change covers all three logout call sites (`ProfilePage.tsx`, `hooks/useAuth.ts`, `lib/api.ts`'s 401 interceptor) since they all call `useAuthStore.getState().clearAuth()`.

- [ ] **Step 1: Write the failing test**

```typescript
// src/stores/authStore.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useAuthStore } from './authStore'
import { removePersistedCache } from '@/lib/persister'

vi.mock('@/lib/persister', () => ({ removePersistedCache: vi.fn() }))

describe('authStore.clearAuth', () => {
  beforeEach(() => vi.mocked(removePersistedCache).mockClear())

  it('clears the persisted query cache on logout', () => {
    useAuthStore.getState().clearAuth()
    expect(removePersistedCache).toHaveBeenCalledOnce()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:unit -- src/stores/authStore.test.ts`
Expected: FAIL — `removePersistedCache` not called (mock not invoked).

- [ ] **Step 3: Implement**

```diff
 import { create } from 'zustand'
 import type { User } from '@/types'
+import { removePersistedCache } from '@/lib/persister'
```

```diff
   clearAuth: () => {
     localStorage.removeItem('user')
+    removePersistedCache()
     set({ user: null })
   },
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run test:unit -- src/stores/authStore.test.ts`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add src/stores/authStore.ts src/stores/authStore.test.ts
git commit -m "feat: clear persisted query cache on logout"
```

---

### Task 10: Migrate mutations — admin batch 1 (Contracts, FeeConfig, Invoices, Maintenance)

**Files:**
- Modify: `src/features/admin/pages/ContractsPage.tsx`
- Modify: `src/features/admin/pages/FeeConfigPage.tsx`
- Modify: `src/features/admin/pages/InvoicesPage.tsx`
- Modify: `src/features/admin/pages/MaintenancePage.tsx`

**Interfaces:**
- Consumes: `useGuardedMutation` (Task 4).

This and Tasks 11-16 are mechanical: swap the `useMutation` import for `useGuardedMutation` and rename each mutation declaration. No other line changes — `.mutate(...)` call sites keep working because `useGuardedMutation` returns the same shape (see Task 4).

- [ ] **Step 1: `ContractsPage.tsx`**

```diff
-import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 78, 86, 97 — change `useMutation({` to `useGuardedMutation({` (declarations: `terminateMutation`, `renewMutation`, `createMutation`).

- [ ] **Step 2: `FeeConfigPage.tsx`**

```diff
-import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Line 55 — change `useMutation({` to `useGuardedMutation({` (declaration: `feeMutation`).

- [ ] **Step 3: `InvoicesPage.tsx` (admin)**

```diff
-import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 58, 112 — change `useMutation({` to `useGuardedMutation({` (declarations: `markPaidCashMutation`, `generateMutation`).

- [ ] **Step 4: `MaintenancePage.tsx` (admin)**

```diff
-import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 92, 112, 126, 140, 153 — change `useMutation({` to `useGuardedMutation({` (declarations: `createRequestMutation`, `assignMutation`, `cancelMutation`, `resolveMutation`, `updateSlaMutation`).

- [ ] **Step 5: Verify**

Run: `npm run build`
Expected: TypeScript build succeeds, no errors (this catches any missed rename since `useMutation` would then be an unused import — treated as a lint issue, not a build error; also run `npm run lint` to confirm no unused-import warnings).

- [ ] **Step 6: Commit**

```bash
git add src/features/admin/pages/ContractsPage.tsx src/features/admin/pages/FeeConfigPage.tsx src/features/admin/pages/InvoicesPage.tsx src/features/admin/pages/MaintenancePage.tsx
git commit -m "feat: guard admin contract/fee/invoice/maintenance mutations against offline writes"
```

---

### Task 11: Migrate mutations — admin batch 2 (MeterReadings, Properties, RoomDetail, Rooms)

**Files:**
- Modify: `src/features/admin/pages/MeterReadingsPage.tsx`
- Modify: `src/features/admin/pages/PropertiesPage.tsx`
- Modify: `src/features/admin/pages/RoomDetailPage.tsx`
- Modify: `src/features/admin/pages/RoomsPage.tsx`

**Interfaces:**
- Consumes: `useGuardedMutation` (Task 4).

- [ ] **Step 1: `MeterReadingsPage.tsx`**

```diff
-import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 151, 188 — change `useMutation({` to `useGuardedMutation({` (declarations: `readingMutation`, `hunonicSyncMutation`).

- [ ] **Step 2: `PropertiesPage.tsx`**

```diff
-import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 80, 106, 120, 132, 142 — change `useMutation({` to `useGuardedMutation({` (declarations: `save`, `saveType`, `toggleTypeActive`, `removeType`, `remove`).

- [ ] **Step 3: `RoomDetailPage.tsx`**

```diff
-import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 49, 60 — change `useMutation({` to `useGuardedMutation({` (declarations: `addNote`, `deleteNote`).

- [ ] **Step 4: `RoomsPage.tsx`**

```diff
-import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 68, 96 — change `useMutation({` to `useGuardedMutation({` (declarations: `save`, `remove`).

- [ ] **Step 5: Verify**

Run: `npm run build && npm run lint`
Expected: both succeed with no errors/unused-import warnings.

- [ ] **Step 6: Commit**

```bash
git add src/features/admin/pages/MeterReadingsPage.tsx src/features/admin/pages/PropertiesPage.tsx src/features/admin/pages/RoomDetailPage.tsx src/features/admin/pages/RoomsPage.tsx
git commit -m "feat: guard admin meter/property/room mutations against offline writes"
```

- [ ] **Step 7: Confirm existing test still passes**

Run: `npm run test:unit -- src/features/admin/pages/MeterReadingsPage.test.ts`
Expected: PASS (unchanged — `useGuardedMutation` is transparent when online, and `navigator.onLine` defaults to `true` under jsdom).

---

### Task 12: Migrate mutations — admin batch 3 (SlaConfig, Users)

**Files:**
- Modify: `src/features/admin/pages/SlaConfigPage.tsx`
- Modify: `src/features/admin/pages/UsersPage.tsx`

**Interfaces:**
- Consumes: `useGuardedMutation` (Task 4).

- [ ] **Step 1: `SlaConfigPage.tsx`**

```diff
-import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 27, 41 — change `useMutation({` to `useGuardedMutation({` (declarations: `saveMutation`, `deleteMutation`).

- [ ] **Step 2: `UsersPage.tsx`**

```diff
-import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 55, 64, 78 — change `useMutation({` to `useGuardedMutation({` (declarations: `createUserMutation`, `updateUserMutation`, `toggleActiveMutation`).

- [ ] **Step 3: Verify**

Run: `npm run build && npm run lint`
Expected: both succeed with no errors.

- [ ] **Step 4: Commit**

```bash
git add src/features/admin/pages/SlaConfigPage.tsx src/features/admin/pages/UsersPage.tsx
git commit -m "feat: guard admin sla/user mutations against offline writes"
```

---

### Task 13: Migrate mutations — auth (ChangePassword)

**Files:**
- Modify: `src/features/auth/pages/ChangePasswordPage.tsx`

**Interfaces:**
- Consumes: `useGuardedMutation` (Task 4).

- [ ] **Step 1: `ChangePasswordPage.tsx`**

```diff
-import { useMutation } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Line 17 — change `useMutation({` to `useGuardedMutation({` (declaration: `mutation`).

- [ ] **Step 2: Verify**

Run: `npm run build && npm run lint`
Expected: both succeed with no errors.

- [ ] **Step 3: Commit**

```bash
git add src/features/auth/pages/ChangePasswordPage.tsx
git commit -m "feat: guard change-password mutation against offline writes"
```

---

### Task 14: Migrate mutations — technician maintenance page

**Files:**
- Modify: `src/features/tech/pages/MaintenancePage.tsx`

**Interfaces:**
- Consumes: `useGuardedMutation` (Task 4).

This is the highest-value page for offline guarding per the design spec's motivating scenario (technicians on-site with weak signal).

- [ ] **Step 1: `MaintenancePage.tsx` (tech)**

```diff
-import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 63, 75, 86, 111, 126, 141, 156 — change `useMutation({` to `useGuardedMutation({` (declarations: `startMutation`, `confirmSlotMutation`, `addMaterialMutation`, `deleteMaterialMutation`, `addNoteMutation`, `submitReviewMutation`, `completionImagesMutation`).

- [ ] **Step 2: Verify**

Run: `npm run build && npm run lint`
Expected: both succeed with no errors.

- [ ] **Step 3: Commit**

```bash
git add src/features/tech/pages/MaintenancePage.tsx
git commit -m "feat: guard technician maintenance mutations against offline writes"
```

---

### Task 15: Migrate mutations — tenant pages (Invoices, Maintenance)

**Files:**
- Modify: `src/features/tenant/pages/InvoicesPage.tsx`
- Modify: `src/features/tenant/pages/MaintenancePage.tsx`

**Interfaces:**
- Consumes: `useGuardedMutation` (Task 4).

- [ ] **Step 1: `InvoicesPage.tsx` (tenant)**

```diff
-import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Line 46 — change `useMutation({` to `useGuardedMutation({` (declaration: `cashMutation`).

- [ ] **Step 2: `MaintenancePage.tsx` (tenant)**

```diff
-import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from '@/hooks/useGuardedMutation'
```

Lines 92, 118, 130, 143, 156, 167 — change `useMutation({` to `useGuardedMutation({` (declarations: `createMutation`, `resolveMutation`, `complainMutation`, `reviewMutation`, `payMaterialMutation`, `tenantConfirmSlotMutation`).

- [ ] **Step 3: Verify**

Run: `npm run build && npm run lint`
Expected: both succeed with no errors.

- [ ] **Step 4: Commit**

```bash
git add src/features/tenant/pages/InvoicesPage.tsx src/features/tenant/pages/MaintenancePage.tsx
git commit -m "feat: guard tenant invoice/maintenance mutations against offline writes"
```

---

### Task 16: Migrate mutations — `useNotifications.ts`

**Files:**
- Modify: `src/hooks/useNotifications.ts`

**Interfaces:**
- Consumes: `useGuardedMutation` (Task 4).

- [ ] **Step 1: `useNotifications.ts`**

```diff
-import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
+import { useQuery, useQueryClient } from '@tanstack/react-query'
+import { useGuardedMutation } from './useGuardedMutation'
```

Lines 52, 57 — change `useMutation({` to `useGuardedMutation({` (declarations: `markRead`, `markAllRead`).

- [ ] **Step 2: Verify**

Run: `npm run build && npm run lint`
Expected: both succeed with no errors.

- [ ] **Step 3: Commit**

```bash
git add src/hooks/useNotifications.ts
git commit -m "feat: guard notification mutations against offline writes"
```

---

### Task 17: Full-suite verification and manual offline QA

**Files:** none (verification only)

- [ ] **Step 1: Run the full unit test suite**

Run: `npm run test:unit`
Expected: all tests PASS, including the new tests from Tasks 1-6, 9, and the pre-existing suite (`adminMaintenanceCreateForm.test.ts`, `MeterReadingsPage.test.ts`, `test-infrastructure.test.ts`, `tests/completionImageFlow.test.ts`, `tests/sessionExpiryMessage.test.ts`, `tests/sessionExpiryPolicy.test.ts`).

- [ ] **Step 2: Run lint and build**

Run: `npm run lint && npm run build`
Expected: both succeed with zero errors/warnings.

- [ ] **Step 3: Manual offline QA (Chrome DevTools "Offline" throttle)**

1. `npm run dev`, log in, browse a few pages (e.g. properties, an invoice list, a maintenance request) to populate the persisted cache.
2. Open DevTools → Network tab → set throttling to "Offline".
3. Reload the page. Expected: last-seen data renders (no blank page, no infinite spinner); `OfflineBanner` is visible with the Vietnamese offline message.
4. Attempt a write action (e.g. mark a notification as read, or edit a room). Expected: a toast reports no network connection; no request appears in the Network tab; the underlying data is unchanged after restoring connectivity.
5. Set throttling back to "Online" (or "No throttling"). Expected: `OfflineBanner` disappears within a few seconds; a background refetch occurs (visible in the Network tab).
6. Log out while online. Expected: no errors in the console; `localStorage` no longer contains the `htr-query-cache` key (verify via DevTools → Application → Local Storage).

- [ ] **Step 4: Record results**

If any manual QA step fails, stop and open a task documenting the failure (file, expected vs. actual) rather than committing further work on top of it. If all steps pass, no code changes are needed for this task — it is a verification checkpoint only.
