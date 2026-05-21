import { cn } from '@/lib/utils'
import { forwardRef } from 'react'

interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  label?: string
  error?: string
}

const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ className, label, error, children, ...props }, ref) => (
    <div className="space-y-1">
      {label && (
        <label className="block text-sm font-medium text-fg">{label}</label>
      )}
      <select
        ref={ref}
        className={cn(
          'w-full rounded-lg border border-border px-3 py-2 text-sm text-fg bg-surface',
          'focus:border-accent focus:ring-2 focus:ring-accent/20 focus:outline-none',
          'transition-colors duration-100',
          error && 'border-error-border',
          className
        )}
        {...props}
      >
        {children}
      </select>
      {error && <p className="text-xs text-error">{error}</p>}
    </div>
  )
)
Select.displayName = 'Select'

export { Select }
