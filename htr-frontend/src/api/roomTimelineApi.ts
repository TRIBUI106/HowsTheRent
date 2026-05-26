import api from '@/lib/api'
import type { RoomTimelineEntry, RoomNote } from '@/types'

export const roomTimelineApi = {
  getTimeline: (roomId: string) =>
    api.get<RoomTimelineEntry[]>(`/rooms/${roomId}/timeline`).then(r => r.data),

  addNote: (roomId: string, content: string) =>
    api.post<RoomNote>(`/rooms/${roomId}/notes`, { content }).then(r => r.data),

  deleteNote: (roomId: string, noteId: string) =>
    api.delete(`/rooms/${roomId}/notes/${noteId}`),
}
