import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClientProvider } from '@tanstack/react-query'
import { PersistQueryClientProvider } from '@tanstack/react-query-persist-client'
import { BrowserRouter } from 'react-router-dom'
import { createAppQueryClient } from '@/lib/queryClient'
import { getPersister, CACHE_BUSTER } from '@/lib/persister'
import App from './App'
import ToastViewport from '@/components/ToastViewport'
import './index.css'

const queryClient = createAppQueryClient()
const persister = getPersister()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      {persister ? (
        <PersistQueryClientProvider
          client={queryClient}
          persistOptions={{ persister, buster: CACHE_BUSTER }}
        >
          <App />
          <ToastViewport />
        </PersistQueryClientProvider>
      ) : (
        <QueryClientProvider client={queryClient}>
          <App />
          <ToastViewport />
        </QueryClientProvider>
      )}
    </BrowserRouter>
  </StrictMode>,
)
