# Frontend Query Cache Persistence & Offline Read Support — Design

**Date:** 2026-08-23
**Status:** Approved for planning
**Scope:** `htr-frontend` only (no backend changes)

## Problem

The frontend already uses `@tanstack/react-query` for server-state caching
(`main.tsx`, global `staleTime: 60s`, no persistence) and `zustand` for
client state (`stores/authStore.ts`). There is no caching layer question to
solve from scratch — the gap is:

1. Cache is lost on every page reload (in-memory only) — the app always
   starts from a blank/loading state even for data that hasn't changed.
2. No distinction between fast-changing and slow-changing data — everything
   shares the same 60s `staleTime`, causing avoidable refetches for
   near-static reference data (property types, SLA rules, fee configs).
3. No offline handling at all — losing connectivity mid-session (e.g. a
   technician on-site with weak signal) currently means failed requests,
   retry storms, and no indication to the user of what's happening.

## Goals

- Persist the React Query cache across page reloads/app restarts, for all
  roles (Admin/Tenant/Technician) equally — no data-sensitivity tiering.
- Reduce redundant refetches for reference data that rarely changes.
- When offline: keep showing last-known cached data (read-only), block
  write actions with a clear message. **No mutation queueing / background
  sync** — out of scope by explicit decision.
- Clear persisted cache on logout (shared-machine hygiene) and on app
  version bump (avoid loading stale/incompatible cache shape after a
  deploy).

## Non-goals

- Installable PWA / service worker / offline app-shell (static asset
  caching). Noted as a possible future upgrade, not part of this design.
- Mutation queueing, conflict resolution, background sync of writes made
  while offline.
- Per-data-type sensitivity tiering in the persister (explicitly rejected
  by product decision — everything persists the same way).

## Architecture

No new caching layer is introduced. The existing `QueryClient` is extended
with a persistence plugin, plus a thin "network awareness" layer used to
gate write actions.

```
main.tsx
  └─ PersistQueryClientProvider (replaces QueryClientProvider)
        ├─ queryClient   (src/lib/queryClient.ts)
        └─ persister     (src/lib/persister.ts, localStorage-backed)

src/lib/queryClient.ts     — QueryClient factory (staleTime/gcTime defaults)
src/lib/persister.ts       — createSyncStoragePersister + buster config
src/lib/mutationGuard.ts   — guardMutate(isOnline, fn) helper
src/hooks/useOnlineStatus.ts — online/offline browser event hook
src/components/OfflineBanner.tsx — global banner, mounted in App shell
```

No changes to `api/*.ts` files or the existing `useQuery` call-site pattern
(inline `useQuery({...})` per page/hook — no query-key factory exists today
and this design doesn't introduce one). Only specific reference-data
queries get an explicit `staleTime` override.

### Components

| File | Responsibility | New dependency |
|---|---|---|
| `lib/queryClient.ts` | `QueryClient` factory: existing `retry`/`staleTime` logic from `main.tsx` moved here, plus `gcTime` set high enough to outlive the persist window (24h) | none |
| `lib/persister.ts` | `createSyncStoragePersister({ storage: window.localStorage })`, `buster` = app version, wrapped in try/catch for storage-unavailable fallback | `@tanstack/query-sync-storage-persister`, `@tanstack/react-query-persist-client` |
| `hooks/useOnlineStatus.ts` | Subscribes to `window` `online`/`offline` events, returns current boolean | none |
| `components/OfflineBanner.tsx` | Renders a dismissable-by-reconnect banner when `useOnlineStatus()` is false; states data may be stale | `useOnlineStatus` |
| `lib/mutationGuard.ts` | `guardMutate(isOnline, mutateFn)`: if offline, shows a toast and returns without calling `mutateFn`; otherwise calls it | `useOnlineStatus`, existing `lib/toast` |

## Data flow

1. **Boot**: `PersistQueryClientProvider` restores the cache from
   `localStorage` before queries run (`isRestoring`), avoiding a flash of
   empty state that would otherwise trigger an unnecessary refetch race.
2. **Normal online use**: `useQuery` behaves as today. On every cache
   change, the persister throttles writes (~1s) of the full cache to
   `localStorage`.
3. **Going offline**: `navigator.onLine` flips false → browser `offline`
   event → `useOnlineStatus` updates → `OfflineBanner` appears. React
   Query's built-in `onlineManager` listens to the same browser events and
   pauses in-flight/pending queries (`networkMode: 'online'`, the default)
   — no retry storms, no thrown network errors. Components keep rendering
   the last cached `data` (`fetchStatus: 'paused'`).
4. **Write attempted while offline**: every mutation call-site is wrapped
   with `guardMutate(isOnline, () => mutation.mutate(...))`. Offline → toast
   shown, `mutate()` never invoked, no optimistic update left dangling. No
   queueing.
5. **Back online**: browser `online` event → banner clears → React Query
   auto-resumes/refetches paused queries. Independently, the existing SSE
   `EventSource` (which reconnects per browser default behavior) fires its
   `notification`/`maintenance-update` handlers and calls
   `invalidateQueries` as it already does today — a harmless extra fetch on
   top of React Query's own resume, keeping data honestly fresh.
6. **Logout**: existing logout handler additionally calls
   `persister.removeClient()` to wipe the persisted cache — defense in
   depth against a shared machine showing the next user stale data client
   side (server-side auth already prevents actual data access).
7. **Deploy / version bump**: `buster` (app version, injected via Vite
   `define`/`import.meta.env`) changes → persist plugin detects the
   mismatch on restore and discards the old cache wholesale rather than
   attempting to load an incompatible shape → avoids runtime errors from a
   stale cached object shape after a schema change.

## Error handling & edge cases

- **`localStorage` unavailable/full** (private browsing, quota, disabled
  storage): `persister.ts` wraps persister creation/writes in try/catch; on
  failure it logs a `console.warn` and the app continues without
  persistence — equivalent to current behavior before this feature existed.
  Never a hard failure.
- **Stale-looking offline data**: `OfflineBanner` explicitly states data may
  not be up to date, so cached reads are never silently presented as live.
- **Mutation in flight when connection drops mid-request** (as opposed to
  attempted while already offline): surfaces as a normal network error
  through the existing axios error-toast path — not special-cased by this
  design.
- **Multi-role shared browser**: covered by the logout-clears-cache step
  above; no per-role cache separation needed since logout always wipes it.
- Query keys are unchanged — no new cross-role data-leak surface.

## Testing

- Unit: `useOnlineStatus` — dispatch synthetic `online`/`offline` window
  events (vitest + jsdom), assert hook state transitions.
- Unit: `guardMutate` — offline: mutate fn not called, toast called; online:
  mutate fn called, no toast.
- Unit: `persister.ts` fallback — mock `localStorage.setItem` to throw,
  assert setup does not throw and app still renders.
- Component test: `OfflineBanner` — shows/hides based on the hook state.
- Manual QA (Chrome DevTools "Offline" throttle), run once before merge:
  1. Load app online, browse a few pages to populate cache.
  2. Reload while offline → verify last-seen data renders (no blank/stuck
     spinner).
  3. Attempt a write action while offline → verify it's blocked with a
     toast and no network request is made.
  4. Restore connectivity → verify banner clears and data silently
     refreshes.
- No Playwright e2e coverage added in this iteration (offline simulation
  via `context.setOffline(true)` is possible but adds meaningful suite
  runtime for a first cut) — noted as a natural follow-up, not a blocker.

## Rejected alternatives

- **Full PWA (service worker via `vite-plugin-pwa`)**: would add
  installable-app / static-asset offline support on top of everything
  above. Not requested (no installability requirement), and adds
  meaningfully more operational complexity (SW lifecycle, cache-busting on
  deploy). Left as a future option, not part of this design.
- **Hand-rolled cache module bypassing React Query's persistence**:
  rejected — would re-implement staleness/invalidation/dedup logic React
  Query already provides correctly. Violates YAGNI.
