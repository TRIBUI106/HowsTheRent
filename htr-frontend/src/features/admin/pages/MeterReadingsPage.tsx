import { useMemo, useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { CardsSkeleton } from '@/components/ui/feedback'
import { getRoomPropertyName } from '@/lib/apiMappers'
import { formatMonth, formatCurrencyInput, parseCurrencyInput } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import api from '@/lib/api'
import { Search } from 'lucide-react'
import type { Room, Property } from '@/types'

type ReadingMode = 'MANUAL' | 'HUNONIC'

interface ReadingForm {
  elecOld: string
  elecNew: string
  waterOld: string
  waterNew: string
  elecReplaced: boolean
  elecOldMeterFinal: string
  elecNewMeterStart: string
  waterReplaced: boolean
  waterOldMeterFinal: string
  waterNewMeterStart: string
  serviceFeeOverride: string
}

interface MeterReadingHistory {
  readingMonth: string
  elecOld?: number | null
  elecNew: number
  waterOld?: number | null
  waterNew?: number | null
  elecReplaced?: boolean
  elecOldMeterFinal?: number | null
  elecNewMeterStart?: number | null
  waterReplaced?: boolean
  waterOldMeterFinal?: number | null
  waterNewMeterStart?: number | null
  serviceFeeOverride?: number | null
}

interface MeterReadingSeed {
  previous: MeterReadingHistory | null
  current: MeterReadingHistory | null
}

interface HunonicPreview {
  roomId: string
  roomNumber: string
  propertyName: string
  readingMonth: string
  configured: boolean
  status: string
  message: string
  suggestedElecOld?: number | null
  suggestedWaterOld?: number | null
}

interface HunonicSyncResult {
  roomId: string
  readingMonth: string
  configured: boolean
  created: boolean
  message: string
}

type ApiError = {
  response?: { data?: { message?: string } }
  message?: string
}

function getErrorMessage(error: unknown, fallback: string) {
  const apiError = error as ApiError
  return apiError.response?.data?.message ?? apiError.message ?? fallback
}

const emptyForm = (): ReadingForm => ({
  elecOld: '', elecNew: '', waterOld: '', waterNew: '',
  elecReplaced: false, elecOldMeterFinal: '', elecNewMeterStart: '',
  waterReplaced: false, waterOldMeterFinal: '', waterNewMeterStart: '',
  serviceFeeOverride: '',
})
const MAX_READING_DELTA = 100_000

function currentYearMonth() {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

function getMonthDate(month: string) {
  return `${month}-01`
}

// Clears any locally cached entry for `month` so the component falls back to fresh
// server-derived state (the `readingSeeds` query) instead of stale, never-reconciled
// `forms`/`successRooms` data left over from an earlier visit to that month.
// Exported for unit testing only.
// eslint-disable-next-line react-refresh/only-export-components
export function withMonthCleared<T>(map: Record<string, T>, month: string): Record<string, T> {
  if (!(month in map)) return map
  const rest = { ...map }
  delete rest[month]
  return rest
}

export default function MeterReadingsPage() {
  const qc = useQueryClient()
  const [selectedMonth, setSelectedMonth] = useState(currentYearMonth())
  const [mode, setMode] = useState<ReadingMode>('MANUAL')
  const [search, setSearch] = useState('')
  const [forms, setForms] = useState<Record<string, Record<string, ReadingForm>>>({})
  const [successRooms, setSuccessRooms] = useState<Record<string, Set<string>>>({})
  const [editingRooms, setEditingRooms] = useState<Record<string, Set<string>>>({})
  const [generating, setGenerating] = useState(false)
  const [genResult, setGenResult] = useState<string | null>(null)

  const { data: rooms = [], isLoading } = useQuery<Room[]>({
    queryKey: ['rooms-rented'],
    queryFn: () => api.get('/rooms/rented').then((r) => r.data),
  })

  const roomIds = useMemo(() => rooms.map((room) => room.id).join(','), [rooms])

  const { data: properties = [] } = useQuery<Property[]>({
    queryKey: ['properties'],
    queryFn: () => api.get('/properties').then((r) => r.data),
  })
  const propertiesById = useMemo(
    () => Object.fromEntries(properties.map((p) => [p.id, p])),
    [properties],
  )

  const propertyIds = useMemo(
    () => [...new Set(rooms.map((room) => room.propertyId))].sort().join(','),
    [rooms],
  )
  const { data: feeConfigsByProperty = {} } = useQuery<Record<string, { serviceFee: number }>>({
    queryKey: ['meter-reading-fee-configs', propertyIds],
    enabled: rooms.length > 0,
    queryFn: async () => {
      const ids = [...new Set(rooms.map((room) => room.propertyId))]
      const entries = await Promise.all(
        ids.map(async (id) => [id, await api.get(`/properties/${id}/fee-config`).then((r) => r.data)] as const),
      )
      return Object.fromEntries(entries)
    },
  })

  // "Chung cư" (CONDO) properties call this fee "Phí quản lý"; everything else uses "Phí dịch vụ".
  function serviceFeeLabel(propertyId: string) {
    return propertiesById[propertyId]?.propertyTypeCode === 'CONDO' ? 'Phí quản lý' : 'Phí dịch vụ'
  }

  const { data: readingSeeds = {}, isLoading: isLoadingPrevious } = useQuery<Record<string, MeterReadingSeed>>({
    queryKey: ['meter-reading-seeds', selectedMonth, roomIds],
    enabled: rooms.length > 0,
    queryFn: async () => {
      const monthDate = getMonthDate(selectedMonth)
      const entries = await Promise.all(
        rooms.map(async (room) => {
          const history = await api.get(`/rooms/${room.id}/meter-readings`).then((r) => r.data as MeterReadingHistory[])
          const previous = history.find((reading) => reading.readingMonth < monthDate) ?? null
          const current = history.find((reading) => reading.readingMonth === monthDate) ?? null
          return [room.id, { previous, current }] as const
        }),
      )
      return Object.fromEntries(entries)
    },
  })

  const { data: hunonicPreview = [], isLoading: isLoadingHunonic } = useQuery<HunonicPreview[]>({
    queryKey: ['hunonic-preview', selectedMonth],
    enabled: mode === 'HUNONIC',
    queryFn: () =>
      api.get('/meter-readings/hunonic-preview', {
        params: { readingMonth: getMonthDate(selectedMonth) },
      }).then((r) => r.data),
  })

  const filteredRooms = useMemo(() => {
    if (!search.trim()) return rooms
    const s = search.trim().toLowerCase()
    return rooms.filter((room) => room.roomNumber.toLowerCase().includes(s) || getRoomPropertyName(room).toLowerCase().includes(s))
  }, [rooms, search])

  const filteredHunonicPreview = useMemo(() => {
    if (!search.trim()) return hunonicPreview
    const s = search.trim().toLowerCase()
    return hunonicPreview.filter((item) => item.roomNumber.toLowerCase().includes(s) || item.propertyName.toLowerCase().includes(s))
  }, [hunonicPreview, search])

  const seededForms = useMemo(() => {
    const nextForms: Record<string, ReadingForm> = {}
    for (const room of rooms) {
      const seed = readingSeeds[room.id]
      const previous = seed?.previous
      const current = seed?.current
      nextForms[room.id] = {
        elecOld: current?.elecOld != null ? String(current.elecOld) : previous?.elecNew != null ? String(previous.elecNew) : '',
        elecNew: current?.elecNew != null ? String(current.elecNew) : '',
        waterOld: current?.waterOld != null ? String(current.waterOld) : previous?.waterNew != null ? String(previous.waterNew) : '',
        waterNew: current?.waterNew != null ? String(current.waterNew) : '',
        elecReplaced: current?.elecReplaced ?? false,
        elecOldMeterFinal: current?.elecOldMeterFinal != null ? String(current.elecOldMeterFinal) : '',
        elecNewMeterStart: current?.elecNewMeterStart != null ? String(current.elecNewMeterStart) : '',
        waterReplaced: current?.waterReplaced ?? false,
        waterOldMeterFinal: current?.waterOldMeterFinal != null ? String(current.waterOldMeterFinal) : '',
        waterNewMeterStart: current?.waterNewMeterStart != null ? String(current.waterNewMeterStart) : '',
        serviceFeeOverride: current?.serviceFeeOverride != null ? formatCurrencyInput(current.serviceFeeOverride) : '',
      }
    }
    return nextForms
  }, [readingSeeds, rooms])

  const activeForms = forms[selectedMonth] ?? seededForms
  const activeSuccessRooms = successRooms[selectedMonth] ?? new Set<string>()
  const activeEditingRooms = editingRooms[selectedMonth] ?? new Set<string>()

  const readingMutation = useGuardedMutation({
    mutationFn: ({ roomId, data }: { roomId: string; data: object }) =>
      api.post(`/rooms/${roomId}/meter-readings`, data),
    onSuccess: (response, variables) => {
      const saved = response.data as MeterReadingHistory
      setForms((previous) => ({
        ...previous,
        [selectedMonth]: {
          ...(previous[selectedMonth] ?? seededForms),
          [variables.roomId]: {
            elecOld: saved.elecOld != null ? String(saved.elecOld) : '',
            elecNew: String(saved.elecNew),
            waterOld: saved.waterOld != null ? String(saved.waterOld) : '',
            waterNew: saved.waterNew != null ? String(saved.waterNew) : '',
            elecReplaced: saved.elecReplaced ?? false,
            elecOldMeterFinal: saved.elecOldMeterFinal != null ? String(saved.elecOldMeterFinal) : '',
            elecNewMeterStart: saved.elecNewMeterStart != null ? String(saved.elecNewMeterStart) : '',
            waterReplaced: saved.waterReplaced ?? false,
            waterOldMeterFinal: saved.waterOldMeterFinal != null ? String(saved.waterOldMeterFinal) : '',
            waterNewMeterStart: saved.waterNewMeterStart != null ? String(saved.waterNewMeterStart) : '',
            serviceFeeOverride: saved.serviceFeeOverride != null ? formatCurrencyInput(saved.serviceFeeOverride) : '',
          },
        },
      }))
      setSuccessRooms((previous) => {
        const current = previous[selectedMonth] ?? new Set<string>()
        return {
          ...previous,
          [selectedMonth]: new Set([...current, variables.roomId]),
        }
      })
      // Re-saving (e.g. via "Sửa lại") should drop the room back out of editing mode.
      setEditingRooms((previous) => {
        const current = previous[selectedMonth]
        if (!current?.has(variables.roomId)) return previous
        const next = new Set(current)
        next.delete(variables.roomId)
        return { ...previous, [selectedMonth]: next }
      })
      showToast({ message: 'Đã lưu chỉ số điện nước', type: 'success' })
      qc.invalidateQueries({ queryKey: ['meter-reading-seeds'] })
      qc.invalidateQueries({ queryKey: ['invoices'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
    },
    onError: (error: unknown) => {
      showToast({
        message: getErrorMessage(error, 'Không thể lưu chỉ số điện nước'),
        type: 'error',
      })
    },
  })

  const hunonicSyncMutation = useGuardedMutation({
    mutationFn: ({ roomId }: { roomId: string }) =>
      api.post(`/rooms/${roomId}/meter-readings/hunonic-sync`, {
        readingMonth: getMonthDate(selectedMonth),
      }).then((r) => r.data as HunonicSyncResult),
    onSuccess: (result) => {
      showToast({
        message: result.message,
        type: result.created ? 'success' : 'info',
      })
      qc.invalidateQueries({ queryKey: ['hunonic-preview'] })
      qc.invalidateQueries({ queryKey: ['meter-reading-seeds'] })
      qc.invalidateQueries({ queryKey: ['invoices'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
    },
    onError: (error: unknown) => {
      showToast({
        message: getErrorMessage(error, 'Không thể đọc chỉ số từ Hunonic'),
        type: 'error',
      })
    },
  })

  function getForm(roomId: string): ReadingForm {
    return activeForms[roomId] ?? emptyForm()
  }

  function updateForm<K extends keyof ReadingForm>(roomId: string, field: K, value: ReadingForm[K]) {
    setForms((previous) => ({
      ...previous,
      [selectedMonth]: {
        ...activeForms,
        [roomId]: { ...getForm(roomId), [field]: value },
      },
    }))
  }

  function validateReading(oldValue: number, newValue: number, label: string) {
    if (!Number.isFinite(oldValue) || !Number.isFinite(newValue)) {
      return `${label} phải là số hợp lệ`
    }
    if (oldValue < 0 || newValue < 0) {
      return `${label} không được âm`
    }
    if (newValue < oldValue) {
      return `${label} mới phải lớn hơn hoặc bằng chỉ số cũ`
    }
    if (newValue - oldValue > MAX_READING_DELTA) {
      return `${label} mới chênh lệch quá lớn so với chỉ số cũ`
    }
    return null
  }

  function submitManualReading(room: Room) {
    const form = getForm(room.id)
    const seed = readingSeeds[room.id]
    const previous = seed?.previous
    const elecOld = Number(form.elecOld)
    const elecNew = Number(form.elecNew)

    let elecOldMeterFinal: number | null = null
    let elecNewMeterStart: number | null = null
    if (form.elecReplaced) {
      if (!form.elecOldMeterFinal.trim() || !form.elecNewMeterStart.trim()) {
        showToast({ message: 'Đã thay đồng hồ điện: vui lòng nhập chỉ số đồng hồ cũ trước khi tháo và chỉ số đồng hồ mới lúc lắp', type: 'error' })
        return
      }
      elecOldMeterFinal = Number(form.elecOldMeterFinal)
      elecNewMeterStart = Number(form.elecNewMeterStart)
      const oldSegError = validateReading(elecOld, elecOldMeterFinal, 'Chỉ số đồng hồ điện cũ (trước khi tháo)')
      if (oldSegError) { showToast({ message: oldSegError, type: 'error' }); return }
      const newSegError = validateReading(elecNewMeterStart, elecNew, 'Chỉ số đồng hồ điện mới')
      if (newSegError) { showToast({ message: newSegError, type: 'error' }); return }
    } else {
      const elecError = validateReading(elecOld, elecNew, 'Chỉ số điện')
      if (elecError) {
        showToast({ message: elecError, type: 'error' })
        return
      }
    }

    const hasWater = form.waterOld.trim() || form.waterNew.trim()
    const waterOld = form.waterOld ? Number(form.waterOld) : null
    const waterNew = form.waterNew ? Number(form.waterNew) : null
    let waterOldMeterFinal: number | null = null
    let waterNewMeterStart: number | null = null
    if (hasWater) {
      if (waterOld == null || waterNew == null) {
        showToast({ message: 'Vui lòng nhập đủ chỉ số nước cũ và mới', type: 'error' })
        return
      }
      if (form.waterReplaced) {
        if (!form.waterOldMeterFinal.trim() || !form.waterNewMeterStart.trim()) {
          showToast({ message: 'Đã thay đồng hồ nước: vui lòng nhập chỉ số đồng hồ cũ trước khi tháo và chỉ số đồng hồ mới lúc lắp', type: 'error' })
          return
        }
        waterOldMeterFinal = Number(form.waterOldMeterFinal)
        waterNewMeterStart = Number(form.waterNewMeterStart)
        const oldSegError = validateReading(waterOld, waterOldMeterFinal, 'Chỉ số đồng hồ nước cũ (trước khi tháo)')
        if (oldSegError) { showToast({ message: oldSegError, type: 'error' }); return }
        const newSegError = validateReading(waterNewMeterStart, waterNew, 'Chỉ số đồng hồ nước mới')
        if (newSegError) { showToast({ message: newSegError, type: 'error' }); return }
      } else {
        const waterError = validateReading(waterOld, waterNew, 'Chỉ số nước')
        if (waterError) {
          showToast({ message: waterError, type: 'error' })
          return
        }
      }
    }

    // Kỳ trước đã có chỉ số → chỉ số cũ luôn lấy từ chỉ số mới của kỳ trước, không cho tự sửa
    const lockedElecOld = previous?.elecNew ?? elecOld
    const lockedWaterOld = previous?.waterNew ?? waterOld

    readingMutation.mutate({
      roomId: room.id,
      data: {
        readingMonth: getMonthDate(selectedMonth),
        elecOld: lockedElecOld,
        elecNew,
        waterOld: lockedWaterOld,
        waterNew,
        elecReplaced: form.elecReplaced,
        elecOldMeterFinal,
        elecNewMeterStart,
        waterReplaced: form.waterReplaced,
        waterOldMeterFinal,
        waterNewMeterStart,
        serviceFeeOverride: form.serviceFeeOverride.trim() ? parseCurrencyInput(form.serviceFeeOverride) : null,
        source: 'MANUAL',
      },
    })
  }

  async function generateInvoices() {
    setGenerating(true)
    setGenResult(null)
    try {
      const [year, month] = selectedMonth.split('-').map(Number)
      const { data } = await api.post('/invoices/generate', null, { params: { year, month } })
      const message = data.message ?? 'Đã tạo hóa đơn'
      setGenResult(message)
      showToast({ message, type: 'success' })
      qc.invalidateQueries({ queryKey: ['invoices'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
    } catch (error: unknown) {
      const message = getErrorMessage(error, 'Không thể tạo hóa đơn')
      setGenResult(`Lỗi: ${message}`)
      showToast({ message, type: 'error' })
    } finally {
      setGenerating(false)
    }
  }

  const monthDate = useMemo(() => getMonthDate(selectedMonth), [selectedMonth])

  return (
    <Layout title="Chỉ số điện nước">
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-fg">Chỉ số điện nước</h1>
            <p className="mt-1 text-sm text-fg-muted">
              Hiện có 2 kiểu nhập: `Manual` và `Hunonic`. Mặc định ưu tiên nhập tay trong giai đoạn chưa có thiết bị.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div>
              <label className="mb-1 block text-xs text-fg-muted">Tìm phòng</label>
              <div className="relative">
                <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-fg-subtle" />
                <input
                  type="text"
                  placeholder="Số phòng, toà nhà..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-52 rounded-xl border border-border bg-surface pl-9 pr-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                />
              </div>
            </div>

            <div>
              <label className="mb-1 block text-xs text-fg-muted">Tháng</label>
              <input
                type="month"
                value={selectedMonth}
                onChange={(event) => {
                  const nextMonth = event.target.value
                  setSelectedMonth(nextMonth)
                  setForms((previous) => withMonthCleared(previous, nextMonth))
                  setSuccessRooms((previous) => withMonthCleared(previous, nextMonth))
                  setEditingRooms((previous) => withMonthCleared(previous, nextMonth))
                  setGenResult(null)
                }}
                className="rounded-xl border border-border/80 bg-surface px-3 py-2 text-sm text-fg focus:outline-none focus:ring-2 focus:ring-accent"
              />
            </div>

            <div className="pt-5">
              <Button variant="primary" onClick={generateInvoices} disabled={generating}>
                {generating ? 'Đang tạo...' : 'Tạo hóa đơn tháng này'}
              </Button>
            </div>
          </div>
        </div>

        <div className="flex flex-wrap gap-2">
          {[
            { id: 'MANUAL' as const, label: 'Manual', helper: 'Nhập tay, ưu tiên dùng ngay' },
            { id: 'HUNONIC' as const, label: 'Hunonic', helper: 'Khung sẵn để nối thiết bị sau' },
          ].map((item) => (
            <button
              key={item.id}
              onClick={() => setMode(item.id)}
              className={`rounded-2xl border px-4 py-3 text-left transition-colors ${
                mode === item.id
                  ? 'border-accent bg-accent-surface text-fg'
                  : 'border-border bg-surface text-fg-muted hover:text-fg'
              }`}
            >
              <p className="text-sm font-semibold">{item.label}</p>
              <p className="mt-1 text-xs">{item.helper}</p>
            </button>
          ))}
        </div>

        {genResult && (
          <div className={`rounded-xl px-4 py-3 text-sm ${
            genResult.startsWith('Lỗi:')
              ? 'bg-error-surface text-error'
              : 'bg-success-surface text-success'
          }`}
          >
            {genResult}
          </div>
        )}

        {mode === 'MANUAL' && (
          <>
            {isLoading ? (
              <CardsSkeleton count={6} />
            ) : (
              <>
                <p className="text-sm text-fg-muted">
                  {search.trim() ? `${filteredRooms.length}/${rooms.length}` : rooms.length} phòng đang thuê
                </p>

                <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                  {filteredRooms.map((room) => {
                    const form = getForm(room.id)
                    const seed = readingSeeds[room.id]
                    const previous = seed?.previous
                    const isEditing = activeEditingRooms.has(room.id)
                    const done = activeSuccessRooms.has(room.id) && !isEditing

                    return (
                      <Card key={room.id} className={`p-4 ${done ? 'border-success/40 bg-success-surface' : ''}`}>
                        <div className="mb-3 flex items-center justify-between">
                          <div>
                            <p className="font-semibold text-fg">{room.roomNumber}</p>
                            <p className="text-xs text-fg-muted">{getRoomPropertyName(room)}</p>
                          </div>
                          {done && (
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-medium text-success">✓ Đã lưu</span>
                              <button
                                type="button"
                                className="text-xs font-medium text-accent underline underline-offset-2 hover:text-accent/80"
                                onClick={() => setEditingRooms((prev) => {
                                  const current = prev[selectedMonth] ?? new Set<string>()
                                  return { ...prev, [selectedMonth]: new Set([...current, room.id]) }
                                })}
                              >
                                Sửa lại
                              </button>
                            </div>
                          )}
                        </div>

                        {!done && (
                          <div className="space-y-3">
                            <div className="rounded-xl border border-border/70 bg-sidebar/60 px-3 py-2 text-xs text-fg-muted">
                              {isLoadingPrevious ? (
                                <p>Đang lấy chỉ số kỳ trước...</p>
                              ) : previous ? (
                                <p>
                                  Kỳ trước {formatMonth(previous.readingMonth)} đã chốt cho tháng {formatMonth(monthDate)}:
                                  điện {previous.elecNew} kWh
                                  {previous.waterNew != null ? `, nước ${previous.waterNew} m³` : ''}.
                                </p>
                              ) : (
                                <p>Chưa có kỳ trước để tự điền. Vui lòng nhập chỉ số cũ cho kỳ đầu tiên.</p>
                              )}
                            </div>

                            <div className="grid grid-cols-2 gap-2">
                              <div>
                                <label className="mb-1 block text-xs text-fg-muted">Điện cũ (kWh)</label>
                                <Input
                                  type="number"
                                  placeholder="0"
                                  value={form.elecOld}
                                  disabled={!!previous}
                                  onChange={(event) => updateForm(room.id, 'elecOld', event.target.value)}
                                />
                              </div>
                              <div>
                                <label className="mb-1 block text-xs text-fg-muted">Điện mới (kWh)</label>
                                <Input
                                  type="number"
                                  placeholder="0"
                                  value={form.elecNew}
                                  onChange={(event) => updateForm(room.id, 'elecNew', event.target.value)}
                                />
                              </div>
                            </div>

                            {previous && (
                              <div className="space-y-2">
                                <label className="flex items-center gap-2 text-xs text-fg-muted">
                                  <input
                                    type="checkbox"
                                    checked={form.elecReplaced}
                                    onChange={(event) => updateForm(room.id, 'elecReplaced', event.target.checked)}
                                  />
                                  Đã thay đồng hồ điện kỳ này
                                </label>
                                {form.elecReplaced && (
                                  <div className="grid grid-cols-2 gap-2 rounded-lg border border-warning/40 bg-warning-surface/40 p-2">
                                    <div>
                                      <label className="mb-1 block text-xs text-fg-muted">Điện cũ - trước khi tháo (kWh)</label>
                                      <Input
                                        type="number"
                                        placeholder="0"
                                        value={form.elecOldMeterFinal}
                                        onChange={(event) => updateForm(room.id, 'elecOldMeterFinal', event.target.value)}
                                      />
                                    </div>
                                    <div>
                                      <label className="mb-1 block text-xs text-fg-muted">Điện mới - lúc lắp (kWh)</label>
                                      <Input
                                        type="number"
                                        placeholder="0"
                                        value={form.elecNewMeterStart}
                                        onChange={(event) => updateForm(room.id, 'elecNewMeterStart', event.target.value)}
                                      />
                                    </div>
                                  </div>
                                )}
                              </div>
                            )}

                            <div className="grid grid-cols-2 gap-2">
                              <div>
                                <label className="mb-1 block text-xs text-fg-muted">Nước cũ (m³)</label>
                                <Input
                                  type="number"
                                  placeholder="Để trống nếu không dùng"
                                  value={form.waterOld}
                                  disabled={!!previous?.waterNew}
                                  onChange={(event) => updateForm(room.id, 'waterOld', event.target.value)}
                                />
                              </div>
                              <div>
                                <label className="mb-1 block text-xs text-fg-muted">Nước mới (m³)</label>
                                <Input
                                  type="number"
                                  placeholder="Để trống nếu không dùng"
                                  value={form.waterNew}
                                  onChange={(event) => updateForm(room.id, 'waterNew', event.target.value)}
                                />
                              </div>
                            </div>

                            {previous?.waterNew != null && (
                              <div className="space-y-2">
                                <label className="flex items-center gap-2 text-xs text-fg-muted">
                                  <input
                                    type="checkbox"
                                    checked={form.waterReplaced}
                                    onChange={(event) => updateForm(room.id, 'waterReplaced', event.target.checked)}
                                  />
                                  Đã thay đồng hồ nước kỳ này
                                </label>
                                {form.waterReplaced && (
                                  <div className="grid grid-cols-2 gap-2 rounded-lg border border-warning/40 bg-warning-surface/40 p-2">
                                    <div>
                                      <label className="mb-1 block text-xs text-fg-muted">Nước cũ - trước khi tháo (m³)</label>
                                      <Input
                                        type="number"
                                        placeholder="0"
                                        value={form.waterOldMeterFinal}
                                        onChange={(event) => updateForm(room.id, 'waterOldMeterFinal', event.target.value)}
                                      />
                                    </div>
                                    <div>
                                      <label className="mb-1 block text-xs text-fg-muted">Nước mới - lúc lắp (m³)</label>
                                      <Input
                                        type="number"
                                        placeholder="0"
                                        value={form.waterNewMeterStart}
                                        onChange={(event) => updateForm(room.id, 'waterNewMeterStart', event.target.value)}
                                      />
                                    </div>
                                  </div>
                                )}
                              </div>
                            )}

                            <div>
                              <label className="mb-1 block text-xs text-fg-muted">
                                {serviceFeeLabel(room.propertyId)} (₫/tháng)
                              </label>
                              <Input
                                type="text"
                                inputMode="numeric"
                                placeholder={formatCurrencyInput(feeConfigsByProperty[room.propertyId]?.serviceFee ?? 0)}
                                value={form.serviceFeeOverride}
                                onChange={(event) => updateForm(room.id, 'serviceFeeOverride', formatCurrencyInput(event.target.value))}
                              />
                              <p className="mt-1 text-[11px] text-fg-subtle">
                                Để trống sẽ dùng mức mặc định của toà nhà; nhập số để đổi riêng cho tháng này.
                              </p>
                            </div>

                            <Button
                              size="sm"
                              variant="primary"
                              className="w-full"
                              onClick={() => submitManualReading(room)}
                              disabled={
                                readingMutation.isPending ||
                                !form.elecOld.trim() || !form.elecNew.trim() ||
                                (form.elecReplaced && (!form.elecOldMeterFinal.trim() || !form.elecNewMeterStart.trim())) ||
                                (form.waterReplaced && (!form.waterOldMeterFinal.trim() || !form.waterNewMeterStart.trim()))
                              }
                            >
                              Lưu chỉ số manual
                            </Button>
                          </div>
                        )}
                      </Card>
                    )
                  })}

                  {filteredRooms.length === 0 && (
                    <div className="col-span-3 py-16 text-center text-fg-subtle">
                      {rooms.length === 0 ? 'Không có phòng đang thuê' : 'Không tìm thấy phòng phù hợp'}
                    </div>
                  )}
                </div>
              </>
            )}
          </>
        )}

        {mode === 'HUNONIC' && (
          <>
            <div className="rounded-2xl border border-warning/40 bg-warning-surface px-4 py-3 text-sm text-fg">
              Chế độ Hunonic đã có khung tích hợp, nhưng hiện chưa có thiết bị/cấu hình thật nên hệ thống chỉ hiển thị trạng thái kết nối.
              Trong giai đoạn này hãy ưu tiên `Manual` để chốt chỉ số và tạo hóa đơn.
            </div>

            {isLoadingHunonic ? (
              <CardsSkeleton count={6} />
            ) : (
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                {filteredHunonicPreview.map((item) => (
                  <Card key={item.roomId} className="p-4">
                    <div className="mb-3">
                      <p className="font-semibold text-fg">{item.roomNumber}</p>
                      <p className="text-xs text-fg-muted">{item.propertyName}</p>
                    </div>

                    <div className="space-y-3 text-sm">
                      <div className={`rounded-xl px-3 py-2 ${
                        item.configured
                          ? 'bg-success-surface text-success'
                          : 'bg-sidebar text-fg-muted'
                      }`}
                      >
                        <p className="font-medium">
                          {item.configured ? 'Đã sẵn sàng đọc từ Hunonic' : 'Chưa cấu hình Hunonic'}
                        </p>
                        <p className="mt-1 text-xs">{item.message}</p>
                      </div>

                      <div className="grid grid-cols-2 gap-2 rounded-xl border border-border/70 bg-surface px-3 py-2">
                        <div>
                          <p className="text-xs text-fg-muted">Điện cũ gợi ý</p>
                          <p className="mt-1 font-medium text-fg">{item.suggestedElecOld ?? '—'}</p>
                        </div>
                        <div>
                          <p className="text-xs text-fg-muted">Nước cũ gợi ý</p>
                          <p className="mt-1 font-medium text-fg">{item.suggestedWaterOld ?? '—'}</p>
                        </div>
                      </div>

                      <Button
                        size="sm"
                        variant={item.configured ? 'primary' : 'secondary'}
                        className="w-full"
                        onClick={() => hunonicSyncMutation.mutate({ roomId: item.roomId })}
                        disabled={hunonicSyncMutation.isPending}
                      >
                        {item.configured ? 'Đọc từ Hunonic' : 'Thử kết nối Hunonic'}
                      </Button>
                    </div>
                  </Card>
                ))}

                {filteredHunonicPreview.length === 0 && (
                  <div className="col-span-3 py-16 text-center text-fg-subtle">
                    {hunonicPreview.length === 0 ? 'Không có phòng đang thuê để kiểm tra Hunonic' : 'Không tìm thấy phòng phù hợp'}
                  </div>
                )}
              </div>
            )}
          </>
        )}
      </div>
    </Layout>
  )
}
