import { useAuthStore } from '@/stores/authStore'
import { authApi } from '@/api/authApi'
import { userApi } from '@/api/userApi'
import { useNavigate } from 'react-router-dom'

export function useAuth() {
  const { user, setUser, clearAuth } = useAuthStore()
  const navigate = useNavigate()

  const login = async (email: string, password: string) => {
    await authApi.login(email, password)
    const me = await userApi.me()
    setUser(me)
    const role = me.role
    navigate(role === 'ADMIN' ? '/admin' : role === 'TENANT' ? '/tenant' : '/tech', { replace: true })
  }

  const logout = () => {
    authApi.logout().catch(() => {})
    clearAuth()
    navigate('/login', { replace: true })
  }

  return { user, isAuthenticated: !!user, login, logout }
}
