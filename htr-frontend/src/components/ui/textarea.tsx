import { cn } from '@/lib/utils'
import { forwardRef } from 'react'

interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string
  error?: string
}

const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ className, label, error, ...props }, ref) => (
    <div className="space-y-1">
      {label && (
        <label className="block text-sm font-medium text-fg">{label}</label>
      )}
      <textarea
        ref={ref}
        rows={3}
        className={cn(
          'w-full rounded-lg border border-border px-3 py-2 text-sm text-fg bg-surface',
          'placeholder:text-fg-subtle',
          'focus:border-accent focus:ring-2 focus:ring-accent/20 focus:outline-none',
          'resize-none transition-colors duration-100',
          error && 'border-error-border',
          className
        )}
        {...props}
      />
      {error && <p className="text-xs text-error">{error}</p>}
    </div>
  )
)
Textarea.displayName = 'Textarea'

export { Textarea }
