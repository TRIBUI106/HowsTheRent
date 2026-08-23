import { create } from 'zustand'
import type { User } from '@/types'
import { removePersistedCache } from '@/lib/persister'

interface AuthState {
  user: User | null
  setUser: (user: User) => void
  clearAuth: () => void
}

function getStoredUser() {
  try {
    return JSON.parse(localStorage.getItem('user') || 'null') as User | null
  } catch {
    localStorage.removeItem('user')
    return null
  }
}

export const useAuthStore = create<AuthState>((set) => ({
  user: getStoredUser(),
  setUser: (user) => {
    localStorage.setItem('user', JSON.stringify(user))
    set({ user })
  },
  clearAuth: () => {
    localStorage.removeItem('user')
    removePersistedCache()
    set({ user: null })
  },
}))