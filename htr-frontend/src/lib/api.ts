import axios from 'axios'
import type { InternalAxiosRequestConfig } from 'axios'

const baseURL = import.meta.env.VITE_API_BASE_URL
  ? `${import.meta.env.VITE_API_BASE_URL}/api`
  : '/api'

const api = axios.create({
  baseURL,
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken')
  if (token) config.headers.set('Authorization', `Bearer ${token}`)
  return config
})

// Single in-flight refresh promise — prevents concurrent refresh races
let refreshing: Promise<string> | null = null

api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config as InternalAxiosRequestConfig & { _retry?: boolean }
    if (error.response?.status === 401 && !original._retry) {
      original._retry = true
      const refreshToken = localStorage.getItem('refreshToken')
      if (!refreshToken) {
        localStorage.removeItem('accessToken')
        window.location.href = '/login'
        return Promise.reject(error)
      }
      try {
        if (!refreshing) {
          refreshing = axios
            .post<{ accessToken: string; refreshToken: string }>(
              `${baseURL}/auth/refresh`,
              { refreshToken },
            )
            .then(({ data }) => {
              if (!data.accessToken) throw new Error('Invalid refresh response')
              localStorage.setItem('accessToken', data.accessToken)
              localStorage.setItem('refreshToken', data.refreshToken)
              return data.accessToken
            })
            .finally(() => {
              refreshing = null
            })
        }
        const newToken = await refreshing
        original.headers.set('Authorization', `Bearer ${newToken}`)
        return api(original)
      } catch {
        localStorage.removeItem('accessToken')
        localStorage.removeItem('refreshToken')
        window.location.href = '/login'
        return Promise.reject(error)
      }
    }
    return Promise.reject(error)
  },
)

export default api
