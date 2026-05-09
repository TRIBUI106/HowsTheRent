import api from '@/lib/api'
import type { Contract } from '@/types'

export const contractApi = {
  listByRoom: (roomId: string) =>
    api.get<Contract[]>(`/rooms/${roomId}/contracts`).then(r => r.data),
  listAll: () => api.get<Contract[]>('/contracts').then(r => r.data),
  getById: (id: string) => api.get<Contract>(`/contracts/${id}`).then(r => r.data),
  create: (roomId: string, data: { tenantId: string; moveInDate: string; depositAmount: number; notes?: string }) =>
    api.post<Contract>(`/rooms/${roomId}/contracts`, data).then(r => r.data),
  terminate: (id: string, notes?: string) =>
    api.put<Contract>(`/contracts/${id}/terminate`, { notes }).then(r => r.data),
}
