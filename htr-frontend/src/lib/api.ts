import axios from 'axios'
import type { InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '@/stores/authStore'
import { showToast } from '@/lib/toast'

const baseURL = import.meta.env.DEV
  ? '/api'
  : `${import.meta.env.VITE_API_BASE_URL ?? ''}/api`

const api = axios.create({
  baseURL,
  headers: { 'Content-Type': 'application/json' },
  withCredentials: true,
})

let refreshing: Promise<void> | null = null
let sessionExpired = false

function expireSession(reason?: string) {
  if (sessionExpired) return
  sessionExpired = true
  if (reason) {
    showToast({ message: reason, type: 'error', durationMs: 4500 })
  }
  useAuthStore.getState().clearAuth()
  if (window.location.pathname !== '/login') {
    window.location.href = '/login'
  }
}

api.interceptors.response.use(
  (res) => {
    if (res.config.url === '/auth/login') {
      sessionExpired = false
    }
    return res
  },
  async (error) => {
    const original = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    if (error.response?.status === 502) {
      expireSession('Máy chủ tạm thời không phản hồi (502). Vui lòng đăng nhập lại.')
      return Promise.reject(error)
    }

    if (
      error.response?.status === 401 &&
      !original._retry &&
      original.url !== '/auth/login' &&
      original.url !== '/auth/refresh' &&
      !sessionExpired
    ) {
      original._retry = true

      try {
        if (!refreshing) {
          refreshing = axios
            .post(`${baseURL}/auth/refresh`, {}, { withCredentials: true })
            .then(() => undefined)
            .catch((refreshError) => {
              expireSession('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.')
              throw refreshError
            })
            .finally(() => {
              refreshing = null
            })
        }

        await refreshing
        return api(original)
      } catch {
        return Promise.reject(error)
      }
    }

    return Promise.reject(error)
  },
)

export function isUnauthorizedError(error: unknown) {
  return axios.isAxiosError(error) && error.response?.status === 401
}

export default api
