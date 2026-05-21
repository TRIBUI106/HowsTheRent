import api from '@/lib/api'
import type { User, Page } from '@/types'

export const userApi = {
  listAll: () => api.get<Page<User>>('/users').then(r => r.data.content ?? []),
  getById: (id: string) => api.get<User>(`/users/${id}`).then(r => r.data),
  create: (data: { fullName: string; email: string; phone?: string; password: string; role: string }) =>
    api.post<User>('/users', data).then(r => r.data),
  update: (id: string, data: Partial<{ fullName: string; phone: string; avatarUrl: string; active: boolean; role: string }>) =>
    api.put<User>(`/users/${id}`, data).then(r => r.data),
}
