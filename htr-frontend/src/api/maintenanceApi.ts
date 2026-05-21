import api from '@/lib/api'
import type { MaintenanceRequest, Page } from '@/types'

export const maintenanceApi = {
  listAll: () => api.get<Page<MaintenanceRequest>>('/maintenance').then(r => r.data.content ?? []),
  listMine: () => api.get<Page<MaintenanceRequest>>('/maintenance/my').then(r => r.data.content ?? []),
  getById: (id: string) => api.get<MaintenanceRequest>(`/maintenance/${id}`).then(r => r.data),
  create: (data: { roomId: string; title: string; description?: string }) =>
    api.post<MaintenanceRequest>('/maintenance', data).then(r => r.data),
  assign: (id: string, technicianId: string) =>
    api.put<MaintenanceRequest>(`/maintenance/${id}/assign`, { technicianId }).then(r => r.data),
  resolve: (id: string) =>
    api.put<MaintenanceRequest>(`/maintenance/${id}/resolve`).then(r => r.data),
}
