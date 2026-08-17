import { describe, expect, it, vi } from 'vitest'

// This test file imports the real component module (not a parallel copy of its logic).
// The repo's vitest config has no path-alias resolution for '@/*' and no jsdom/RTL set up
// (see final report FYI), so the component's '@/...' dependencies are stubbed here purely to
// allow the module to load — none of these stubs are exercised by the assertions below, which
// only target the exported `withMonthCleared` pure function.
vi.mock('@/components/Layout', () => ({ default: () => null }))
vi.mock('@/components/ui/card', () => ({ Card: () => null }))
vi.mock('@/components/ui/button', () => ({ Button: () => null }))
vi.mock('@/components/ui/input', () => ({ Input: () => null }))
vi.mock('@/components/ui/feedback', () => ({ CardsSkeleton: () => null }))
vi.mock('@/lib/apiMappers', () => ({ getRoomPropertyName: () => '' }))
vi.mock('@/lib/utils', () => ({ formatMonth: (m: string) => m }))
vi.mock('@/lib/toast', () => ({ showToast: () => {} }))
vi.mock('@/lib/api', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

const { withMonthCleared } = await import('./MeterReadingsPage')

// Regression test for the month-switch state reconciliation bug (introduced in 76e5a0c).
//
// Scenario: an admin saves a meter reading for month "2026-08" (which marks the room as
// "done" in `successRooms` and seeds `forms` with the saved values), switches the month
// selector to "2026-09", then switches back to "2026-08". At that point the page must defer
// to a fresh server read (the `readingSeeds` query) for "2026-08" instead of showing the
// stale, never-reconciled local `forms`/`successRooms` entry from the earlier visit.
//
// `withMonthCleared` is the pure reconciliation helper the month `<input type="month">`
// `onChange` handler calls (for both `forms` and `successRooms`) to clear out any locally
// cached entry for the month being switched to.
describe('withMonthCleared', () => {
  it('clears a previously visited month entry so fresh server data takes over', () => {
    // Simulate: reading saved for month 8 (the mutation's onSuccess handler populates these).
    const successRoomsAfterSave: Record<string, Set<string>> = {
      '2026-08': new Set(['room-1']),
    }
    const formsAfterSave: Record<string, Record<string, { elecOld: string; elecNew: string }>> = {
      '2026-08': { 'room-1': { elecOld: '100', elecNew: '120' } },
    }

    // Switch away to month 9 — month 8's entries must be left untouched (still-relevant
    // session data for the month just saved).
    const successRoomsAfterSwitchTo09 = withMonthCleared(successRoomsAfterSave, '2026-09')
    const formsAfterSwitchTo09 = withMonthCleared(formsAfterSave, '2026-09')
    expect(successRoomsAfterSwitchTo09).toBe(successRoomsAfterSave)
    expect(formsAfterSwitchTo09).toBe(formsAfterSave)
    expect(successRoomsAfterSwitchTo09['2026-08']?.has('room-1')).toBe(true)

    // Switch back to month 8 — the stale, never-reconciled entry for "2026-08" must be
    // cleared so the component falls back to fresh `readingSeeds`-derived state instead of
    // the leftover success marker / cached form values from the earlier visit.
    const successRoomsAfterSwitchBackTo08 = withMonthCleared(successRoomsAfterSwitchTo09, '2026-08')
    const formsAfterSwitchBackTo08 = withMonthCleared(formsAfterSwitchTo09, '2026-08')

    expect(successRoomsAfterSwitchBackTo08['2026-08']).toBeUndefined()
    expect(formsAfterSwitchBackTo08['2026-08']).toBeUndefined()
    expect('2026-08' in successRoomsAfterSwitchBackTo08).toBe(false)
    expect('2026-08' in formsAfterSwitchBackTo08).toBe(false)
  })

  it('returns the same object reference when the target month has no cached entry (no-op)', () => {
    const successRooms: Record<string, Set<string>> = { '2026-08': new Set(['room-1']) }
    const result = withMonthCleared(successRooms, '2026-09')
    expect(result).toBe(successRooms)
  })

  it('removes only the target month, preserving other cached months', () => {
    const forms: Record<string, Record<string, { elecOld: string }>> = {
      '2026-07': { 'room-1': { elecOld: '10' } },
      '2026-08': { 'room-1': { elecOld: '20' } },
    }
    const result = withMonthCleared(forms, '2026-08')
    expect(result['2026-08']).toBeUndefined()
    expect(result['2026-07']).toEqual({ 'room-1': { elecOld: '10' } })
  })
})
