import { cn } from '@/lib/utils'
import { X } from 'lucide-react'
import type { ReactNode } from 'react'

interface DialogProps {
  open: boolean
  onClose: () => void
  title?: string
  children: ReactNode
  className?: string
}

export function Dialog({ open, onClose, title, children, className }: DialogProps) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-fg/40 backdrop-blur-[2px]" onClick={onClose} />
      <div className={cn('relative bg-surface rounded-xl shadow-xl border border-border w-full max-w-lg mx-4 p-6', className)}>
        <div className="flex items-center justify-between mb-5">
          {title && <h2 className="text-base font-semibold text-fg">{title}</h2>}
          <button
            onClick={onClose}
            className="ml-auto text-fg-subtle hover:text-fg transition-colors rounded-md p-0.5"
          >
            <X size={17} />
          </button>
        </div>
        {children}
      </div>
    </div>
  )
}
