import api from '@/lib/api'
import type { Room } from '@/types'

export const roomApi = {
  listByProperty: (propertyId: string) =>
    api.get<Room[]>(`/properties/${propertyId}/rooms`).then(r => r.data),
  listAll: () => api.get<Room[]>('/rooms').then(r => r.data),
  getById: (propertyId: string, id: string) =>
    api.get<Room>(`/properties/${propertyId}/rooms/${id}`).then(r => r.data),
  create: (propertyId: string, data: { roomNumber: string; floor?: number; areaM2?: number; maxPeople: number; rentOverride?: number }) =>
    api.post<Room>(`/properties/${propertyId}/rooms`, data).then(r => r.data),
  update: (propertyId: string, id: string, data: Partial<{ roomNumber: string; floor: number; areaM2: number; maxPeople: number; rentOverride: number }>) =>
    api.put<Room>(`/properties/${propertyId}/rooms/${id}`, data).then(r => r.data),
  updateStatus: (propertyId: string, id: string, status: string) =>
    api.patch<Room>(`/properties/${propertyId}/rooms/${id}/status`, null, { params: { status } }).then(r => r.data),
}
