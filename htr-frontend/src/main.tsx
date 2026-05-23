import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom'
import { isUnauthorizedError } from '@/lib/api'
import App from './App'
import ToastViewport from '@/components/ToastViewport'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (_failureCount, error) => !isUnauthorizedError(error),
      staleTime: 1000 * 60,
    },
    mutations: {
      retry: (_failureCount, error) => !isUnauthorizedError(error),
    },
  },
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
        <App />
        <ToastViewport />
      </QueryClientProvider>
    </BrowserRouter>
  </StrictMode>,
)