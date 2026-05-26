import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { roomApi, roomTimelineApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatCurrency, formatDate } from '@/lib/utils'
import type { RoomTimelineEntry } from '@/types'
import {
  ArrowLeft, User, FileText, Wrench, BarChart2, StickyNote, Trash2,
} from 'lucide-react'

const typeConfig: Record<
  RoomTimelineEntry['type'],
  { icon: React.ComponentType<{ size?: number; className?: string }>; dotColor: string; label: string }
> = {
  CONTRACT_MOVE_IN:  { icon: User,      dotColor: 'bg-badge-green',   label: 'Vào ở'       },
  CONTRACT_MOVE_OUT: { icon: User,      dotColor: 'bg-badge-neutral',  label: 'Rời phòng'   },
  INVOICE:           { icon: FileText,  dotColor: 'bg-badge-blue',     label: 'Hoá đơn'     },
  MAINTENANCE:       { icon: Wrench,    dotColor: 'bg-badge-amber',    label: 'Sửa chữa'    },
  METER_READING:     { icon: BarChart2, dotColor: 'bg-accent',         label: 'Ghi số'      },
  NOTE:              { icon: StickyNote,dotColor: 'bg-badge-neutral',  label: 'Ghi chú'     },
}

export default function RoomDetailPage() {
  const { propertyId, roomId } = useParams<{ propertyId: string; roomId: string }>()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const user = useAuthStore(state => state.user)
  const [noteText, setNoteText] = useState('')

  const { data: room, isLoading: roomLoading } = useQuery({
    queryKey: ['room', propertyId, roomId],
    queryFn: () => roomApi.getById(propertyId!, roomId!),
    enabled: !!user && !!propertyId && !!roomId,
  })

  const { data: timeline, isLoading: timelineLoading } = useQuery({
    queryKey: ['room-timeline', roomId],
    queryFn: () => roomTimelineApi.getTimeline(roomId!),
    enabled: !!user && !!roomId,
  })

  const addNote = useMutation({
    mutationFn: () => roomTimelineApi.addNote(roomId!, noteText.trim()),
    onSuccess: () => {
      setNoteText('')
      qc.invalidateQueries({ queryKey: ['room-timeline', roomId] })
    },
  })

  const deleteNote = useMutation({
    mutationFn: (noteId: string) => roomTimelineApi.deleteNote(roomId!, noteId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['room-timeline', roomId] }),
  })

  if (roomLoading) {
    return (
      <Layout title="Chi tiết phòng">
        <div className="flex h-40 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-accent border-t-transparent rounded-full" />
        </div>
      </Layout>
    )
  }

  return (
    <Layout title={`Phòng ${room?.roomNumber ?? ''}`}>
      <div className="mb-6 flex items-center gap-3">
        <Button variant="secondary" size="sm" onClick={() => navigate('/admin/rooms')}>
          <ArrowLeft size={14} className="mr-1" /> Quay lại
        </Button>
        <span className="text-fg-muted text-sm">{room?.propertyName}</span>
      </div>

      {/* Room info */}
      <Card className="mb-6">
        <CardHeader>
          <div className="flex items-center gap-3">
            <span className="text-lg font-semibold text-fg">Phòng {room?.roomNumber}</span>
            {room && <Badge status={room.status} />}
          </div>
        </CardHeader>
        <CardContent>
          <dl className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <dt className="text-fg-subtle">Tầng</dt>
              <dd className="font-medium text-fg">{room?.floor ?? '—'}</dd>
            </div>
            <div>
              <dt className="text-fg-subtle">Diện tích</dt>
              <dd className="font-medium text-fg">{room?.areaM2 ? `${room.areaM2} m²` : '—'}</dd>
            </div>
            <div>
              <dt className="text-fg-subtle">Tối đa</dt>
              <dd className="font-medium text-fg">{room?.maxPeople} người</dd>
            </div>
            <div>
              <dt className="text-fg-subtle">Giá thuê</dt>
              <dd className="font-medium text-fg">
                {room?.rentOverride ? formatCurrency(room.rentOverride) : 'Theo toà nhà'}
              </dd>
            </div>
          </dl>
        </CardContent>
      </Card>

      {/* Timeline */}
      <Card>
        <CardHeader>Lịch sử phòng</CardHeader>
        <CardContent>
          {/* Add note */}
          <div className="mb-6 rounded-xl border border-border bg-surface/60 p-4">
            <p className="text-sm font-medium text-fg mb-2">Thêm ghi chú</p>
            <textarea
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-fg resize-none focus:outline-none focus:ring-2 focus:ring-accent/40 placeholder:text-fg-subtle"
              rows={2}
              placeholder="Nhập ghi chú cho phòng này..."
              value={noteText}
              onChange={e => setNoteText(e.target.value)}
            />
            <div className="mt-2 flex justify-end">
              <Button
                size="sm"
                onClick={() => addNote.mutate()}
                disabled={!noteText.trim() || addNote.isPending}
                loading={addNote.isPending}
              >
                Lưu ghi chú
              </Button>
            </div>
          </div>

          {timelineLoading ? (
            <div className="flex h-32 items-center justify-center">
              <div className="animate-spin h-5 w-5 border-2 border-accent border-t-transparent rounded-full" />
            </div>
          ) : !timeline?.length ? (
            <p className="text-sm text-fg-subtle text-center py-8">Chưa có sự kiện nào.</p>
          ) : (
            <ol className="relative ml-3">
              {timeline.map((entry, idx) => {
                const cfg = typeConfig[entry.type]
                const Icon = cfg.icon
                const isNote = entry.type === 'NOTE'
                const noteId = isNote ? String((entry.metadata as { noteId: string }).noteId) : null
                return (
                  <li key={idx} className="mb-6 ml-6 last:mb-0">
                    {/* Dot */}
                    <span className={`absolute -left-1.5 flex h-3 w-3 items-center justify-center rounded-full ${cfg.dotColor} ring-2 ring-background`} />

                    {/* Content */}
                    <div className="rounded-xl border border-border bg-surface/60 px-4 py-3">
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex items-center gap-2 min-w-0">
                          <span className="shrink-0 inline-flex h-6 w-6 items-center justify-center rounded-md bg-surface border border-border text-fg-subtle">
                            <Icon size={12} />
                          </span>
                          <span className="text-xs font-medium text-fg-subtle uppercase tracking-wide">{cfg.label}</span>
                        </div>
                        <div className="flex items-center gap-2 shrink-0">
                          <time className="text-xs text-fg-subtle">{formatDate(entry.date)}</time>
                          {isNote && noteId && (
                            <button
                              onClick={() => deleteNote.mutate(noteId)}
                              className="text-fg-subtle hover:text-error transition-colors"
                              disabled={deleteNote.isPending}
                            >
                              <Trash2 size={13} />
                            </button>
                          )}
                        </div>
                      </div>
                      <p className="mt-1.5 text-sm font-medium text-fg">{entry.title}</p>
                      <p className="mt-0.5 text-sm text-fg-muted">{entry.description}</p>
                      {entry.type === 'INVOICE' && (
                        <span className="mt-1.5 inline-block">
                          <Badge status={String((entry.metadata as { invoiceStatus: string }).invoiceStatus)} />
                        </span>
                      )}
                      {(entry.type === 'CONTRACT_MOVE_IN' || entry.type === 'CONTRACT_MOVE_OUT') && (
                        <span className="mt-1.5 inline-block">
                          <Badge status={String((entry.metadata as { contractStatus: string }).contractStatus)} />
                        </span>
                      )}
                      {entry.type === 'MAINTENANCE' && (
                        <span className="mt-1.5 inline-block">
                          <Badge status={String((entry.metadata as { maintenanceStatus: string }).maintenanceStatus)} />
                        </span>
                      )}
                    </div>
                  </li>
                )
              })}
            </ol>
          )}
        </CardContent>
      </Card>
    </Layout>
  )
}
