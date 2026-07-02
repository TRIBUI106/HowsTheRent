import { useEffect, useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { CardsSkeleton } from '@/components/ui/feedback'
import { getRoomPropertyName } from '@/lib/apiMappers'
import { formatMonth } from '@/lib/utils'
import { showToast } from '@/lib/toast'
import api from '@/lib/api'
import type { Room } from '@/types'

type ReadingMode = 'MANUAL' | 'HUNONIC'

interface ReadingForm {
  elecOld: string
  elecNew: string
  waterOld: string
  waterNew: string
}

interface MeterReadingHistory {
  readingMonth: string
  elecNew: number
  waterNew?: number | null
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

const emptyForm = (): ReadingForm => ({ elecOld: '', elecNew: '', waterOld: '', waterNew: '' })

function currentYearMonth() {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

function getMonthDate(month: string) {
  return `${month}-01`
}

export default function MeterReadingsPage() {
  const qc = useQueryClient()
  const [selectedMonth, setSelectedMonth] = useState(currentYearMonth())
  const [mode, setMode] = useState<ReadingMode>('MANUAL')
  const [forms, setForms] = useState<Record<string, ReadingForm>>({})
  const [successRooms, setSuccessRooms] = useState<Set<string>>(new Set())
  const [generating, setGenerating] = useState(false)
  const [genResult, setGenResult] = useState<string | null>(null)

  const { data: rooms = [], isLoading } = useQuery<Room[]>({
    queryKey: ['rooms-rented'],
    queryFn: () => api.get('/rooms/rented').then((r) => r.data),
  })

  const { data: previousReadings = {}, isLoading: isLoadingPrevious } = useQuery<Record<string, MeterReadingHistory | null>>({
    queryKey: ['meter-reading-seeds', selectedMonth, rooms.map((room) => room.id).join(',')],
    enabled: rooms.length > 0,
    queryFn: async () => {
      const monthDate = getMonthDate(selectedMonth)
      const entries = await Promise.all(
        rooms.map(async (room) => {
          const history = await api.get(`/rooms/${room.id}/meter-readings`).then((r) => r.data as MeterReadingHistory[])
          const previous = history.find((reading) => reading.readingMonth < monthDate) ?? null
          return [room.id, previous] as const
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

  useEffect(() => {
    setForms({})
    setSuccessRooms(new Set())
  }, [selectedMonth])

  useEffect(() => {
    if (rooms.length === 0) return

    setForms((previousForms) => {
      const nextForms: Record<string, ReadingForm> = {}

      for (const room of rooms) {
        const current = previousForms[room.id] ?? emptyForm()
        const previous = previousReadings[room.id]

        nextForms[room.id] = {
          elecOld: current.elecOld || (previous?.elecNew != null ? String(previous.elecNew) : ''),
          elecNew: current.elecNew,
          waterOld: current.waterOld || (previous?.waterNew != null ? String(previous.waterNew) : ''),
          waterNew: current.waterNew,
        }
      }

      return nextForms
    })
  }, [previousReadings, rooms])

  const readingMutation = useMutation({
    mutationFn: ({ roomId, data }: { roomId: string; data: object }) =>
      api.post(`/rooms/${roomId}/meter-readings`, data),
    onSuccess: (_data, variables) => {
      setSuccessRooms((previous) => new Set([...previous, variables.roomId]))
      showToast({ message: 'Đã lưu chỉ số điện nước', type: 'success' })
      qc.invalidateQueries({ queryKey: ['meter-reading-seeds'] })
      qc.invalidateQueries({ queryKey: ['invoices'] })
      qc.invalidateQueries({ queryKey: ['dashboard'] })
    },
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể lưu chỉ số điện nước',
        type: 'error',
      })
    },
  })

  const hunonicSyncMutation = useMutation({
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
    onError: (error: any) => {
      showToast({
        message: error?.response?.data?.message ?? 'Không thể đọc chỉ số từ Hunonic',
        type: 'error',
      })
    },
  })

  function getForm(roomId: string): ReadingForm {
    return forms[roomId] ?? emptyForm()
  }

  function updateForm(roomId: string, field: keyof ReadingForm, value: string) {
    setForms((previous) => ({
      ...previous,
      [roomId]: { ...getForm(roomId), [field]: value },
    }))
  }

  function submitManualReading(room: Room) {
    const form = getForm(room.id)
    readingMutation.mutate({
      roomId: room.id,
      data: {
        readingMonth: getMonthDate(selectedMonth),
        elecOld: form.elecOld ? Number(form.elecOld) : null,
        elecNew: Number(form.elecNew),
        waterOld: form.waterOld ? Number(form.waterOld) : null,
        waterNew: form.waterNew ? Number(form.waterNew) : null,
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
    } catch (error: any) {
      const message = error?.response?.data?.message ?? error?.message ?? 'Không thể tạo hóa đơn'
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

          <div className="flex items-center gap-3">
            <div>
              <label className="mb-1 block text-xs text-fg-muted">Tháng</label>
              <input
                type="month"
                value={selectedMonth}
                onChange={(event) => setSelectedMonth(event.target.value)}
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
                <p className="text-sm text-fg-muted">{rooms.length} phòng đang thuê</p>

                <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                  {rooms.map((room) => {
                    const form = getForm(room.id)
                    const previous = previousReadings[room.id]
                    const done = successRooms.has(room.id)

                    return (
                      <Card key={room.id} className={`p-4 ${done ? 'border-success/40 bg-success-surface' : ''}`}>
                        <div className="mb-3 flex items-center justify-between">
                          <div>
                            <p className="font-semibold text-fg">{room.roomNumber}</p>
                            <p className="text-xs text-fg-muted">{getRoomPropertyName(room)}</p>
                          </div>
                          {done && <span className="text-sm font-medium text-success">✓ Đã lưu</span>}
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

                            <div className="grid grid-cols-2 gap-2">
                              <div>
                                <label className="mb-1 block text-xs text-fg-muted">Nước cũ (m³)</label>
                                <Input
                                  type="number"
                                  placeholder="Để trống nếu không dùng"
                                  value={form.waterOld}
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

                            <Button
                              size="sm"
                              variant="primary"
                              className="w-full"
                              onClick={() => submitManualReading(room)}
                              disabled={readingMutation.isPending || !form.elecOld.trim() || !form.elecNew.trim()}
                            >
                              Lưu chỉ số manual
                            </Button>
                          </div>
                        )}
                      </Card>
                    )
                  })}

                  {rooms.length === 0 && (
                    <div className="col-span-3 py-16 text-center text-fg-subtle">Không có phòng đang thuê</div>
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
                {hunonicPreview.map((item) => (
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

                {hunonicPreview.length === 0 && (
                  <div className="col-span-3 py-16 text-center text-fg-subtle">Không có phòng đang thuê để kiểm tra Hunonic</div>
                )}
              </div>
            )}
          </>
        )}
      </div>
    </Layout>
  )
}
