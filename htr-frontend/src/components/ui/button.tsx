import type { ReactNode, ButtonHTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger' | 'outline' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  children: ReactNode
  loading?: boolean
}

export function Button({
  variant = 'primary',
  size = 'md',
  children,
  className,
  loading,
  disabled,
  ...props
}: ButtonProps) {
  const variants = {
    primary:   'bg-accent text-accent-fg hover:bg-accent-hover active:bg-accent-active focus-visible:ring-accent',
    secondary: 'bg-surface text-fg border border-border hover:bg-sidebar active:bg-border focus-visible:ring-accent',
    danger:    'bg-error text-white hover:bg-error-hover active:bg-error-fg focus-visible:ring-error',
    outline:   'border border-border text-fg bg-transparent hover:bg-sidebar active:bg-border focus-visible:ring-accent',
    ghost:     'text-fg-muted hover:bg-sidebar hover:text-fg active:bg-border focus-visible:ring-accent',
  }
  const sizes = {
    sm: 'px-3 py-1.5 text-sm min-h-[34px]',
    md: 'px-4 py-2 text-sm min-h-[38px]',
    lg: 'px-6 py-2.5 text-sm min-h-[44px]',
  }
  return (
    <button
      disabled={disabled || loading}
      className={cn(
        'rounded-lg font-medium transition-colors duration-100',
        'inline-flex items-center justify-center gap-2',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-1',
        'disabled:opacity-50 disabled:cursor-not-allowed',
        variants[variant],
        sizes[size],
        className
      )}
      {...props}
    >
      {loading ? (
        <>
          <svg className="animate-spin h-4 w-4 shrink-0" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
          </svg>
          {children}
        </>
      ) : children}
    </button>
  )
}
