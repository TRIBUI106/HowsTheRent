import { cn } from '@/lib/utils'
import { ChevronDown } from 'lucide-react'
import { forwardRef, useId, type ReactNode } from 'react'

interface SelectProps extends Omit<React.SelectHTMLAttributes<HTMLSelectElement>, 'size'> {
  /** Plain text, or JSX for e.g. a required-field asterisk (`<>Phòng <span>*</span></>`). */
  label?: ReactNode
  error?: string
  /** `md` (default): forms, px-3 py-2 text-sm. `sm`: inline table filters/actions, px-2.5 py-1.5 text-xs. */
  size?: 'sm' | 'md'
  /** Classes for the outer wrapper (e.g. `col-span-*` inside a CSS grid, or width in a flex row) — `className` targets the `<select>` itself. */
  wrapperClassName?: string
}

// Trailing chevron sits at a fixed offset from the border regardless of size —
// mirrors DatePicker's CalendarDays icon (absolute right-3, input reserves pr-10)
// so every dropdown in the app has identical icon-to-border spacing.
const sizes = {
  sm: { select: 'px-2.5 py-1.5 pr-8 text-xs', icon: 14, iconWrap: 'right-2.5' },
  md: { select: 'px-3 py-2 pr-10 text-sm', icon: 16, iconWrap: 'right-3' },
}

const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ className, wrapperClassName, label, error, children, id, size = 'md', ...props }, ref) => {
    const generatedId = useId()
    const selectId = id ?? generatedId
    const { select: sizeClass, icon: iconSize, iconWrap } = sizes[size]

    return (
      <div className={cn('space-y-1', wrapperClassName)}>
        {label && (
          <label htmlFor={selectId} className="block text-sm font-medium text-fg">{label}</label>
        )}
        <div className="relative">
          <select
            id={selectId}
            ref={ref}
            className={cn(
              'w-full appearance-none rounded-lg border border-border bg-surface text-fg',
              'focus:border-accent focus:ring-2 focus:ring-accent/20 focus:outline-none',
              'transition-colors duration-100',
              'disabled:cursor-not-allowed disabled:opacity-60',
              sizeClass,
              error && 'border-error-border',
              className
            )}
            {...props}
          >
            {children}
          </select>
          <ChevronDown
            size={iconSize}
            className={cn('pointer-events-none absolute top-1/2 -translate-y-1/2 text-fg-subtle', iconWrap)}
          />
        </div>
        {error && <p className="text-xs text-error">{error}</p>}
      </div>
    )
  }
)
Select.displayName = 'Select'

export { Select }
