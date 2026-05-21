import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface CardProps {
  children: ReactNode
  className?: string
}

export function Card({ children, className }: CardProps) {
  return (
    <div className={cn('rounded-2xl border border-border/90 bg-surface shadow-[0_1px_2px_rgba(15,23,42,0.03)]', className)}>
      {children}
    </div>
  )
}

export function CardHeader({ children, className }: CardProps) {
  return (
    <div className={cn('px-5 py-4 border-b border-border/80', className)}>{children}</div>
  )
}

export function CardContent({ children, className }: CardProps) {
  return (
    <div className={cn('px-5 py-4', className)}>{children}</div>
  )
}
