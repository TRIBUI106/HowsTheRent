import { useAuthStore } from '@/stores/authStore'
import { authApi } from '@/api'
import { useNavigate } from 'react-router-dom'

export function useAuth() {
  const { user, setUser, clearAuth } = useAuthStore()
  const navigate = useNavigate()

  const login = async (email: string, password: string) => {
    const { user } = await authApi.login(email, password)
    setUser(user)
    const role = user.role
    navigate(role === 'ADMIN' ? '/admin' : role === 'TENANT' ? '/tenant' : '/tech', { replace: true })
  }

  const logout = () => {
    authApi.logout().catch(() => {})
    clearAuth()
    navigate('/login', { replace: true })
  }

  return { user, isAuthenticated: !!user, login, logout }
}
