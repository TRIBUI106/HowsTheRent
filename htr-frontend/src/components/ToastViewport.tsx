import { useEffect, useState } from 'react'
import { getToastEventName } from '@/lib/toast'

type ToastItem = {
  id: number
  message: string
  type: 'info' | 'success' | 'error'
}

export default function ToastViewport() {
  const [items, setItems] = useState<ToastItem[]>([])

  useEffect(() => {
    const eventName = getToastEventName()

    const onToast = (event: Event) => {
      const custom = event as CustomEvent<{ message: string; type?: 'info' | 'success' | 'error'; durationMs?: number }>
      const message = custom.detail?.message
      if (!message) return

      const id = Date.now() + Math.floor(Math.random() * 1000)
      const type = custom.detail?.type ?? 'info'
      const duration = custom.detail?.durationMs ?? 3000

      setItems(prev => [...prev, { id, message, type }])
      window.setTimeout(() => {
        setItems(prev => prev.filter(item => item.id !== id))
      }, duration)
    }

    window.addEventListener(eventName, onToast as EventListener)
    return () => window.removeEventListener(eventName, onToast as EventListener)
  }, [])

  return (
    <div className="pointer-events-none fixed right-4 top-4 z-[100] flex w-[320px] flex-col gap-2">
      {items.map(item => (
        <div
          key={item.id}
          className={
            item.type === 'error'
              ? 'rounded-xl border border-error/30 bg-error px-4 py-3 text-sm text-white shadow-lg'
              : item.type === 'success'
                ? 'rounded-xl border border-success/30 bg-success px-4 py-3 text-sm text-white shadow-lg'
                : 'rounded-xl border border-accent/30 bg-fg px-4 py-3 text-sm text-white shadow-lg'
          }
        >
          {item.message}
        </div>
      ))}
    </div>
  )
}
