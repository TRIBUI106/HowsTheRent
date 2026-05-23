import api from '@/lib/api'
import type { AuthResponse, User } from '@/types'

export const authApi = {
  login: (email: string, password: string) =>
    api.post<AuthResponse>('/auth/login', { email, password }).then(r => r.data),
  me: () => api.get<User>('/users/me').then(r => r.data),
  logout: () => api.post('/auth/logout').then(r => r.data),
}
