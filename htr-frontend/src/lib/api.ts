import axios from 'axios'
import type { InternalAxiosRequestConfig } from 'axios'

const baseURL = import.meta.env.DEV
  ? '/api'
  : `${import.meta.env.VITE_API_BASE_URL ?? ''}/api`

const api = axios.create({
  baseURL,
  headers: { 'Content-Type': 'application/json' },
  withCredentials: true,
})

let refreshing: Promise<void> | null = null

api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    if (
      error.response?.status === 401 &&
      !original._retry &&
      original.url !== '/auth/login' &&
      original.url !== '/auth/refresh'
    ) {
      original._retry = true

      try {
        if (!refreshing) {
          refreshing = axios
            .post(`${baseURL}/auth/refresh`, {}, { withCredentials: true })
            .then(() => undefined)
            .finally(() => {
              refreshing = null
            })
        }

        await refreshing
        return api(original)
      } catch {
        localStorage.removeItem('user')
        window.location.href = '/login'
        return Promise.reject(error)
      }
    }

    return Promise.reject(error)
  },
)

export default api
