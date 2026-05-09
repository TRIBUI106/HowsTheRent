import { useAuthStore } from '@/stores/authStore'
import { authApi } from '@/api/authApi'
import { useNavigate } from 'react-router-dom'

export function useAuth() {
  const { user, accessToken, setAuth, clearAuth } = useAuthStore()
  const navigate = useNavigate()

  const login = async (email: string, password: string) => {
    const data = await authApi.login(email, password)
    setAuth(data.user, data.accessToken, data.refreshToken)
    const role = data.user.role
    navigate(role === 'ADMIN' ? '/admin' : role === 'TENANT' ? '/tenant' : '/tech', { replace: true })
  }

  const logout = () => {
    authApi.logout().catch(() => {})
    clearAuth()
    navigate('/login', { replace: true })
  }

  return { user, accessToken, isAuthenticated: !!accessToken, login, logout }
}
