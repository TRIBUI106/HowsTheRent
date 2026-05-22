import { create } from 'zustand'
import type { User } from '@/types'

interface AuthState {
  user: User | null
  setUser: (user: User) => void
  clearAuth: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  user: JSON.parse(localStorage.getItem('user') || 'null'),
  setUser: (user) => {
    localStorage.setItem('user', JSON.stringify(user))
    set({ user })
  },
  clearAuth: () => {
    localStorage.removeItem('user')
    set({ user: null })
  },
}))