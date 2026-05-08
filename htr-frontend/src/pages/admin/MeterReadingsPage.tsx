import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Spinner } from '@/components/ui/feedback'
import api from '@/lib/api'
import type { Room } from '@/types'

interface ReadingForm {
  elecOld: string
  elecNew: string
  waterOld: string
  waterNew: string
}

const emptyForm = (): ReadingForm => ({ elecOld: '', elecNew: '', waterOld: '', waterNew: '' })

function currentYearMonth() {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

export default function MeterReadingsPage() {
  const qc = useQueryClient()
  const [selectedMonth, setSelectedMonth] = useState(currentYearMonth())
  const [forms, setForms] = useState<Record<string, ReadingForm>>({})
  const [successRooms, setSuccessRooms] = useState<Set<string>>(new Set())
  const [generating, setGenerating] = useState(false)
  const [genResult, setGenResult] = useState<string | null>(null)

  const { data: rooms, isLoading } = useQuery<Room[]>({
    queryKey: ['rooms-all'],
    queryFn: () => api.get('/rooms').then(r => r.data),
  })

  const readingMutation = useMutation({
    mutationFn: ({ roomId, data }: { roomId: string; data: object }) =>
      api.post(`/rooms/${roomId}/meter-readings`, data),
    onSuccess: (_data, vars) => {
      setSuccessRooms(prev => new Set([...prev, vars.roomId]))
      setForms(prev => ({ ...prev, [vars.roomId]: emptyForm() }))
      qc.invalidateQueries({ queryKey: ['rooms-all'] })
    },
  })

  function getForm(roomId: string): ReadingForm {
    return forms[roomId] ?? emptyForm()
  }

  function updateForm(roomId: string, field: keyof ReadingForm, value: string) {
    setForms(prev => ({ ...prev, [roomId]: { ...getForm(roomId), [field]: value } }))
  }

  function submitReading(room: Room) {
    const f = getForm(room.id)
    readingMutation.mutate({
      roomId: room.id,
      data: {
        readingMonth: `${selectedMonth}-01`,
        elecOld: Number(f.elecOld),
        elecNew: Number(f.elecNew),
        waterOld: f.waterOld ? Number(f.waterOld) : null,
        waterNew: f.waterNew ? Number(f.waterNew) : null,
      },
    })
  }

  async function generateInvoices() {
    setGenerating(true)
    setGenResult(null)
    try {
      const [y, m] = selectedMonth.split('-').map(Number)
      const { data } = await api.post(`/invoices/generate?year=${y}&month=${m}`)
      setGenResult(data.message ?? 'Invoices generated')
    } catch (e: any) {
      setGenResult('Error: ' + (e?.response?.data?.message ?? e.message))
    } finally {
      setGenerating(false)
    }
  }

  const rentedRooms = rooms?.filter(r => r.status === 'RENTED') ?? []

  return (
    <Layout>
      <div className="p-6 space-y-6">
        <div className="flex items-center justify-between flex-wrap gap-4">
          <h1 className="text-2xl font-bold text-gray-900">Chỉ số điện nước</h1>
          <div className="flex items-center gap-3">
            <div>
              <label className="block text-xs text-gray-500 mb-1">Tháng</label>
              <input
                type="month"
                value={selectedMonth}
                onChange={e => { setSelectedMonth(e.target.value); setSuccessRooms(new Set()) }}
                className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div className="pt-5">
              <Button
                variant="primary"
                onClick={generateInvoices}
                disabled={generating}
              >
                {generating ? 'Đang tạo…' : '⚡ Tạo hóa đơn tháng này'}
              </Button>
            </div>
          </div>
        </div>

        {genResult && (
          <div className={`rounded-lg px-4 py-3 text-sm ${genResult.startsWith('Error') ? 'bg-red-50 text-red-700' : 'bg-green-50 text-green-700'}`}>
            {genResult}
          </div>
        )}

        {isLoading ? <Spinner /> : (
          <>
            <p className="text-sm text-gray-500">{rentedRooms.length} phòng đang thuê</p>
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
              {rentedRooms.map(room => {
                const f = getForm(room.id)
                const done = successRooms.has(room.id)
                return (
                  <Card key={room.id} className={`p-4 ${done ? 'border-green-400 bg-green-50' : ''}`}>
                    <div className="flex items-center justify-between mb-3">
                      <div>
                        <p className="font-semibold text-gray-900">{room.roomNumber}</p>
                        <p className="text-xs text-gray-500">{room.property?.name}</p>
                      </div>
                      {done && <span className="text-green-600 text-sm font-medium">✓ Đã lưu</span>}
                    </div>
                    {!done && (
                      <div className="space-y-3">
                        <div className="grid grid-cols-2 gap-2">
                          <div>
                            <label className="block text-xs text-gray-500 mb-1">Điện cũ (kWh)</label>
                            <Input
                              type="number"
                              placeholder="0"
                              value={f.elecOld}
                              onChange={e => updateForm(room.id, 'elecOld', e.target.value)}
                            />
                          </div>
                          <div>
                            <label className="block text-xs text-gray-500 mb-1">Điện mới (kWh)</label>
                            <Input
                              type="number"
                              placeholder="0"
                              value={f.elecNew}
                              onChange={e => updateForm(room.id, 'elecNew', e.target.value)}
                            />
                          </div>
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                          <div>
                            <label className="block text-xs text-gray-500 mb-1">Nước cũ (m³)</label>
                            <Input
                              type="number"
                              placeholder="—"
                              value={f.waterOld}
                              onChange={e => updateForm(room.id, 'waterOld', e.target.value)}
                            />
                          </div>
                          <div>
                            <label className="block text-xs text-gray-500 mb-1">Nước mới (m³)</label>
                            <Input
                              type="number"
                              placeholder="—"
                              value={f.waterNew}
                              onChange={e => updateForm(room.id, 'waterNew', e.target.value)}
                            />
                          </div>
                        </div>
                        <Button
                          size="sm"
                          variant="primary"
                          className="w-full"
                          onClick={() => submitReading(room)}
                          disabled={readingMutation.isPending || !f.elecOld || !f.elecNew}
                        >
                          Lưu chỉ số
                        </Button>
                      </div>
                    )}
                  </Card>
                )
              })}
              {rentedRooms.length === 0 && (
                <div className="col-span-3 py-16 text-center text-gray-400">Không có phòng đang thuê</div>
              )}
            </div>
          </>
        )}
      </div>
    </Layout>
  )
}
